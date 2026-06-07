/*
Home 扫码查询索引核查脚本

用途：
1. 查看扫码查询相关表的真实索引。
2. 用一个真实慢条码观察 SQL Server IO 和耗时。
3. 本脚本只读，不创建、不修改任何数据库对象。
*/

-- 1. 查看相关表索引。
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

-- 2. 替换为真实慢条码后，观察执行计划、逻辑读和耗时。
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
