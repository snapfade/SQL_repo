SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==================================================================
-- Author:		Brian Tansy
-- Create date: 1/18/2017
-- Description:	Get all accounts Archtics with duplicate passwords
-- ==================================================================
CREATE PROCEDURE [dbo].[spGetArchticsPasswordDups]
AS
BEGIN
	SET NOCOUNT ON;

	--get all dup passwords
	SELECT * INTO #tblDups FROM OPENQUERY(ARCHTICS,'
		select
			p.pin 
		from dba.t_cust_pin p 
		inner join dba.t_cust_name cn on cn.cust_name_id = p.cust_name_id
		inner join dba.t_customer c on c.cust_name_id = p.cust_name_id
		where c.acct_id in
			(select distinct acct_id from dba.t_ticket where event_id in
				(select event_id from dba.t_event where season_id = ''157''))
		group by p.pin
		having count(p.pin) > 1
	')

	--get ALL accounts from Archtics
	SELECT * INTO #tblAccts FROM 
		OPENQUERY(ARCHTICS,'
			select
				p.pin, 
				p.cust_name_id, 
				cn.name_first, 
				cn.name_last,
				c.add_date,
				c.acct_id,
				ce.email_addr
			from dba.t_cust_pin p 
			inner join dba.t_cust_name cn on cn.cust_name_id = p.cust_name_id
			inner join dba.t_customer c on c.cust_name_id = p.cust_name_id
			inner join dba.t_cust_email ce on cn.cust_name_id = ce.cust_name_id
		') 

	;WITH t1 as
		(SELECT 
			a.pin, 
			a.cust_name_id, 
			a.name_first, 
			a.name_last,
			a.add_date,
			a.acct_id,
			email_addr
		FROM #tblAccts	a
		INNER JOIN #tblDups d on d.pin = a.pin COLLATE Latin1_General_CS_AS
		--ORDER BY a.pin asc, date_added desc
		),
	t2 as
		(SELECT 
			count(*) as pin_count,
			a.pin 
		FROM #tblAccts	a
		INNER JOIN #tblDups d on d.pin = a.pin COLLATE Latin1_General_CS_AS
		GROUP BY a.pin
		HAVING count(*) > 1)
	SELECT 
		* 
	FROM t1 tbl1 
	WHERE 
		exists (SELECT * FROM t2 tbl2 WHERE tbl1.pin = tbl2.pin) 
	ORDER BY tbl1.pin asc, tbl1.add_date desc;

END
GO
