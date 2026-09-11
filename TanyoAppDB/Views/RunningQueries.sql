--select * from RunningQueries
CREATE VIEW [dbo].[RunningQueries]
AS

	SELECT 
		object_name(objectid) as ObjectName, 
		SUBSTRING(st.text, (statement_start_offset/2)+1, 
			((CASE statement_end_offset
			  WHEN -1 THEN DATALENGTH(st.text)
			 ELSE statement_end_offset
			 END - statement_start_offset)/2) + 1) AS statement_text
		, db_name(database_id) as dbname,blocking_session_id as BlockingWith,  *
	FROM
		sys.dm_exec_requests r
	CROSS APPLY 
		sys.dm_exec_sql_text(sql_handle) AS st

GO

