select	ov.[Name], ov.[Rows], RezervedSize = ov.ReservedPages/128
from
	(
		select	o.[object_id], o.[Type_Desc], [Name] = concat(SCHEMA_NAME(o.schema_id), '.', o.[Name]), Parent = po.[Name], x.[Rows], x.ReservedPages
		from	sys.objects o with (nolock)
				left join sys.objects po with (nolock) on o.parent_object_id = po.[object_id]
				left join
                (
                    select  ps.[object_id],
                            [Rows]          = sum(case when ps.index_id < 2 then ps.row_count else 0 end),
                            ReservedPages   = sum(ps.reserved_page_count),
		                    UsedPages       = sum(ps.used_page_count)
                    from    sys.dm_db_partition_stats ps
                    group by ps.[object_id]
                ) x on o.[object_id] = x.[object_id]
	) ov
where   1 = 1
        and ov.[Rows] > 0
order by ReservedPages desc, ov.[Rows] desc, ov.[Type_Desc], ov.[Name];
