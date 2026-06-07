# Home 扫码查询索引核查与优化记录

本文档用于处理 Home 扫码查询速度不足的问题。移动端请求为：

```text
POST /react/v1/store-order/products/scan-lookup
```

后端实现位于 `HBBblazorweb-master-vite`：

```text
BlazorApp.Api/Controllers/React/ReactStoreOrderController.cs
BlazorApp.Api/Services/React/StoreOrderReactService.cs
```

扫码查询当前按 `Product.Barcode`、`Product.ItemNumber`、`Product.ProductCode` 精确匹配，并连接 `WarehouseProduct`、`WarehouseCategory`、`ProductGrade`。`StoreCode` 当前用于权限校验，不参与商品查询过滤。

## 结论

已删除旧的索引创建脚本。生产库已经有接近的索引，真正拖慢扫码查询的是后端把 `Barcode / ItemNumber / ProductCode` 放在同一个 `OR` 查询里，并且在 SQL Server 分支显式使用 `COLLATE Chinese_PRC_CI_AS`。

只读验证结果：

- 旧 `OR + COLLATE` 查询：`Product` 约 7950 预读页，耗时约 272ms。
- 拆成单字段但仍显式 `COLLATE`：`Product` 约 3908 预读页，耗时约 153ms。
- 单字段直接等值比较：`Product` 约 8 逻辑读，耗时约 0ms。

生产库与字段排序规则已经是大小写不敏感：

```text
Database: Chinese_PRC_90_CI_AS
Product.ProductCode: Chinese_PRC_90_CI_AS
Product.ItemNumber: Chinese_PRC_90_CI_AS
Product.Barcode: Chinese_PRC_90_CI_AS
```

因此修复方向是后端查询拆分，并移除 SQL Server 分支的显式 `COLLATE`。

## 1. 只读核查

先在生产 SQL Server 执行下面脚本，确认真实库是否已经具备索引。不要只看仓库里的 SQL 文件，因为后端当前启动配置不会自动创建这些扫码查询索引。

```sql
-- 查看扫码查询相关表的现有索引。
SELECT
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.has_filter AS HasFilter,
    i.filter_definition AS FilterDefinition,
    STRING_AGG(
        c.name + CASE WHEN ic.is_included_column = 1 THEN N' (include)' ELSE N'' END,
        N', '
    ) WITHIN GROUP (ORDER BY ic.is_included_column, ic.key_ordinal, ic.index_column_id) AS Columns
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
LEFT JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
LEFT JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.name IN (N'Product', N'WarehouseProduct', N'WarehouseCategory', N'ProductGrade')
  AND i.name IS NOT NULL
GROUP BY
    t.name,
    i.name,
    i.type_desc,
    i.is_unique,
    i.has_filter,
    i.filter_definition
ORDER BY
    t.name,
    i.name;
```

用一个真实慢条码验证查询是否走索引：

```sql
DECLARE @Barcode NVARCHAR(50) = N'替换为真实慢条码';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    p.ProductCode,
    p.ItemNumber,
    p.Barcode,
    p.ProductName,
    p.ProductImage,
    wc.CategoryName,
    p.WarehouseCategoryGUID,
    wp.OEMPrice,
    wp.MinOrderQuantity,
    wp.StockQuantity,
    p.MiddlePackageQuantity AS PackQty,
    wp.ImportPrice,
    pg.Grade
FROM dbo.Product AS p WITH (NOLOCK)
INNER JOIN dbo.WarehouseProduct AS wp WITH (NOLOCK)
    ON p.ProductCode = wp.ProductCode
LEFT JOIN dbo.WarehouseCategory AS wc WITH (NOLOCK)
    ON p.WarehouseCategoryGUID = wc.CategoryGUID
LEFT JOIN dbo.ProductGrade AS pg WITH (NOLOCK)
    ON p.ProductCode = pg.ProductCode
   AND pg.IsDeleted = 0
WHERE p.IsActive = 1
  AND p.IsDeleted = 0
  AND wp.IsDeleted = 0
  AND wp.IsActive = 1
  AND (
      p.Barcode COLLATE Chinese_PRC_CI_AS = @Barcode
      OR p.ItemNumber COLLATE Chinese_PRC_CI_AS = @Barcode
      OR p.ProductCode COLLATE Chinese_PRC_CI_AS = @Barcode
  );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
```

核查重点：

- `Product` 应优先出现 `Index Seek`，不应对大表做 `Table Scan` 或高成本 `Index Scan`。
- 接口日志中的 `exactQueryMs` 应是主要观察指标；如果 `permissionMs` 更高，瓶颈在权限链路而不是商品索引。
- 如果查询计划仍因 `OR` 不能稳定走索引，后续应把服务层查询拆成主条码、货号、商品编码三段查询。

## 2. 后端修复后验证

后端上线后再跑一次只读核查，并观察移动端扫码日志：

```text
[shop-scan-perf] stage=scan.lookup.controller.done
[shop-scan-perf] stage=scan.lookup.service.done
```

预期结果：

- `exactQueryMs` 明显下降并保持稳定。
- 单个主条码命中时 Home 自动加购链路不再等待长时间商品查询。
- 如果 `exactQueryMs` 仍高，优先查看是否重新引入字段侧函数、显式 `COLLATE` 或 `OR` 条件。

## 3. 后续代码优化入口

当前后端修复入口是 `StoreOrderReactService.ScanLookupProductsAsync`：

- 先查 `Barcode`，命中则直接返回。
- 未命中再查 `ItemNumber` 和 `ProductCode`。
- SQL Server 分支使用字段直接等值比较，不显式指定 `COLLATE`。
