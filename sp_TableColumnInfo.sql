use master;

IF EXISTS (SELECT * FROM dbo.sysObjects WHERE ID = object_id(N'[sp_TableColumnInfo]') AND OBJECTPROPERTY(ID, N'IsProcedure') = 1)
DROP PROCEDURE [sp_TableColumnInfo]
GO

CREATE PROCEDURE [sp_TableColumnInfo]
    @TableName   nvarchar(256),
    @ColumnName  nvarchar(256) = null
AS
BEGIN
  declare @Query nvarchar(MAX) = 
    'select  c.[name], c.column_id, [t].[name], [c].[max_length], [c].[precision], [c].[is_nullable], [c].is_identity, [c].[collation_name], [c].[is_computed], [cc].[definition]
     from    sys.columns [c]
             inner join sys.types [t] on [c].[user_type_id] = [t].[user_type_id]
             left join sys.computed_columns [cc] on [c].[object_id] = [cc].[object_id] and [c].[column_id] = [cc].[column_id]
     where   [c].[object_id] = object_id(@TableName) and [c].[name] = IsNull(@ColumnName, [c].[name]) ;
    '

  exec sp_executesql @query, N'@TableName nvarchar(256), @ColumnName  nvarchar(256)', @TableName, @ColumnName
END
GO
