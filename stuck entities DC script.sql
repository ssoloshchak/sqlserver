set nocount on;

declare @DatabaseNameMask varchar(100) = N'FlexService_PSC2';
declare @EntitiesTriggeredBefore varchar(10) = '20190101'
declare @errors int = 0; -- count of errors during process

-- query template
declare @SQLTemplate nvarchar(max) = 
N'insert into #KPL_info
select ADM.FlexServiceVersie, ''$DATABASE'' DbName, KOP.KoppelingEnum Koppeling, KOP.ActiefInd Enabled, KPL.TransferredInd StateId, KPI.Name State, KPI.Description StateDescription, count(*) as Count 
from  [$DATABASE].dbo.[$TABLE] EXP
      inner join [$DATABASE].dbo.[$TABLE_KPL] KPL on EXP.[$TABLEId] = KPL.[$TABLEId] 
      left join [$DATABASE].dbo.KPL_TransferedInd KPI on KPL.TransferredInd = KPI.TransferedIndID
      left join [$DATABASE].dbo.KPL_Koppeling KOP on KOP.KoppelingId = KPL.KoppelingID
      left join [$DATABASE].dbo.SYS_Administration ADM on 1 = 1
where EXP.WijzigingDT < ''' + @EntitiesTriggeredBefore + '''
and KOP.ParentKoppelingId > 0
group by ADM.FlexServiceVersie, KOP.KoppelingEnum, KOP.ActiefInd, KPL.TransferredInd, KPI.Name, KPI.Description;
';

-- tables list template
declare @tablesTemplate nvarchar(max) = N'select replace([name], ''_KPL'', '''') from [$DATABASE].sys.tables 
where [name] like ''%KPL'' 
  and [name] not like ''%Survey%''  
order by [name];';

if object_id('tempdb..#queries') is not null drop table #queries;
if object_id('tempdb..#KPL_info') IS NOT NULL drop table #KPL_info;

-- the list of dynamic queries to run
create table #queries([id] int identity(1,1) primary key, [query] nvarchar(max));

-- result table
create table #KPL_info
(
   [FlexServiceVersion] varchar(50),
   [DbName]				varchar(50),
   [Koppeling]			varchar(50),
   [Enabled]      int,
   [StateId]			int,
   [State]				varchar(50),
   [StateDescription]	varchar(100),
   [Count]				int
);

/***** PART 1: generate queries *****/

-- cursor for each database
declare db_cursor cursor fast_forward for
select	[name]
from	sys.databases d
where	d.[name] like @DatabaseNameMask;

open db_cursor;
declare @databaseName sysname;
declare @query nvarchar(max);
declare @tablesList table([tableName] sysname);

fetch next from db_cursor into @databaseName;
while @@fetch_status = 0
begin
	
	-- list of tables in database
	set @query = replace(@tablesTemplate, N'$DATABASE', @databaseName);
	insert into @tablesList exec (@query);
	
	-- list of queries
	insert into #queries
	select 	replace(replace(@SQLTemplate, '$DATABASE', @databaseName), '$TABLE', [tl].[tableName])
	from	@tablesList tl

	fetch next from db_cursor into @databaseName;
	delete from @tablesList;
end

close db_cursor;
deallocate db_cursor;

/***** PART 2: execute queries *****/

declare @id int = 1, @max_id int = (select max(id) from #queries);
while @id <= @max_id
begin

	select @query = [query] from #queries where [id] = @id;

	begin try
		exec (@query);
	end try
	begin catch
		print error_message();
		print @query;
		print '';
		set @errors += 1;
	end catch

	set @id += 1;
end


/***** PART 3: show results *****/
if @errors > 0
	select convert(varchar(128), @errors) + ' errors printed!' errors;

select * from #KPL_info;
