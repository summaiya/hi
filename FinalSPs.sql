
/****** Object:  StoredProcedure [dbo].[dbo.Sp_SCPRptDetailItemDiscountByManufacturer]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dbo.Sp_SCPRptDetailItemDiscountByManufacturer]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50) 
AS
BEGIN 
SELECT ManufacturerName AS Manufacture_Name,TTL_ITM AS TotalItem,TotalAmount AS TotalPurchase,Discount_ITM AS NumberOfDiscountItem,
 Discount_VAL AS DiscountValue,
 CONVERT(varchar,ISNULL((Discount_VAL*100)/TotalAmount,0)) AS PercentageOfDiscountValue FROM 
  (
  SELECT SCPStManufactutrer.ManufacturerName,COUNT(SCPTnGoodReceiptNote_D.ItemCode) AS TTL_ITM,SUM(SCPTnGoodReceiptNote_D.NetAmount) AS TotalAmount,
  (SELECT COUNT(PRCD.ItemCode) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteDetailId = PRCM.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PRCD.ItemCode
   WHERE PRCD.DiscountValue !=0 
  AND ITM.ManufacturerId=SCPStItem_M.ManufacturerId 
  AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)
  ) AS Discount_ITM ,
   (SELECT SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*PRCD.TotalAmount) END)  FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteDetailId = PRCM.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PRCD.ItemCode
   WHERE PRCD.DiscountValue !=0 
  AND ITM.ManufacturerId=SCPStItem_M.ManufacturerId 
  AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)
  ) AS Discount_VAL 
  FROM SCPTnGoodReceiptNote_D
  INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
  INNER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId
  WHERE
   cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date)
    BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
	AND CAST(CONVERT(date,@paramToDate,103) as date)
	AND SCPStItem_M.ItemTypeId = @paramItemTypeId
  GROUP BY SCPStItem_M.ManufacturerId,SCPStManufactutrer.ManufacturerName
  )TMP
--WITH CTE_manufacturerDiscount(ManufactureName, 
--							  TotalItem,
--							  TotalPurchase,
--							  DiscountValue,
--							  NumberOfNotDiscountItem,
--							  NumberOfDiscountItem
--							  )
--AS
--(
--	SELECT  Manufacture.ManufacturerName AS ManufactureName,
--			SUM(ItemPurchaseD.RecievedQty) AS TotalItem,
--			SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
--			SUM(ItemPurchaseD.TotalAmount - ItemPurchaseD.AfterDiscountAmount) DiscountValue ,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
--	FROM [dbo].[SCPStManufactutrerCategory] AS Manufacture
--	INNER JOIN [dbo].[SCPStItem_M] AS ItemManufacture ON Manufacture.ManufacturerId = ItemManufacture.ManufacturerId 
--	INNER JOIN [dbo].[SCPTnPharmacyIssuance_D] AS ItemPurchaseD ON ItemManufacture.ItemCode = ItemPurchaseD.ItemCode
--	WHERE  cast(ItemManufacture.CreatedDate as date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
--			AND CAST(CONVERT(date,@paramToDate,103) as date) AND
--		  ItemManufacture.ItemTypeId = @paramItemTypeId

--	GROUP BY Manufacture.ManufacturerName
--)

--SELECT ManufactureName, 
--	   ISNULL(TotalItem,0) AS TotalItem,
--	   ISNULL(TotalPurchase,0) AS TotalPurchase,
--	   ISNULL(DiscountValue,0) AS DiscountValue,
--	   ISNULL(NumberOfDiscountItem,0) AS NumberOfDiscountItem,
--	   ISNULL(NumberOfNotDiscountItem, 0) AS NumberOfNotDiscountItem,
--	   CONVERT(VARCHAR,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))	 AS PercentageOfDiscountValue
--FROM CTE_manufacturerDiscount

END
GO
/****** Object:  StoredProcedure [dbo].[GetPatient]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetInPatient]
(

@patId varchar(50)
)
as
begin
select * from SCPTnInPatient
where  PatientIp=@patId
end
GO
/****** Object:  StoredProcedure [dbo].[InventoryVsCOGS]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
  
  CREATE PROC [dbo].[Sp_SCPGetInventoryVsCOGS] 

  AS BEGIN
  
  DECLARE @STOCK_VALUE AS MONEY, @COGS AS MONEY	
   	
	SELECT @STOCK_VALUE=SUM(STOCK_VALUE) FROM
	(
	    SELECT SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,(ISNULL((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=SCPTnStock_M.WraehouseId AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(CreatedDate as date) <= EOMONTH(dateadd(m, -1,GETDATE())) ORDER BY CreatedDate DESC),0)*(CASE 
		WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode --AND WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D WHERE SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode 
		                          AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
   		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStItem_M.IsActive=1 AND ItemTypeId=2 
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate 
	)TMP 

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	    AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	    AND EOMONTH(dateadd(m, -1,GETDATE()))
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	 SELECT @COGS/@STOCK_VALUE

	 END
GO
/****** Object:  StoredProcedure [dbo].[InventoryVsCOGS_dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



	 CREATE PROC [dbo].[Sp_SCPGetInventoryVsCOGSForDashboard] 

  AS BEGIN
  
  DECLARE @STOCK_VALUE AS MONEY, @COGS AS MONEY	, @PERCENTAGE_AVG_COGS AS VARCHAR(10)
   	
	SELECT @STOCK_VALUE=SUM(STOCK_VALUE) FROM
	(
	    SELECT SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,(ISNULL((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=SCPTnStock_M.WraehouseId AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(CreatedDate as date) <= CAST(GETDATE()-1 AS DATE) ORDER BY CreatedDate DESC),0)*(CASE 
		WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode --AND WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnPharmacyIssuance_D WHERE SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode 
		                          AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
   		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStItem_M.IsActive=1 AND ItemTypeId=2 
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.WraehouseId,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate 
	)TMP 

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)  AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	SELECT @PERCENTAGE_AVG_COGS = '1.2%' 

	 SELECT CASE WHEN @COGS!=0 THEN format(@COGS/@STOCK_VALUE,'##.##') ELSE format(0,'##.##') END as AVG_INVENTORY_VS_COGS , 
	 @PERCENTAGE_AVG_COGS AS PERCENTAGE_INV_VS_COGS

	 END
GO
/****** Object:  StoredProcedure [dbo].[ItemBySupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetItemBySupplier]
@paramSupplierId AS INT
AS
BEGIN
SELECT  ItemMaster.ItemCode,
		ItemMaster.ItemName AS ItemName
	    FROM [dbo].[SCPStItem_D_Supplier] AS ItemSupp
INNER JOIN [dbo].[SCPStItem_M] AS ItemMaster ON ItemSupp.ItemCode = ItemMaster.ItemCode
WHERE ItemSupp.SupplierId = @paramSupplierId
END

GO

/****** Object:  StoredProcedure [dbo].[PurchaseVsCOGS_DASHBOARD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[Sp_SCPGetPurchaseVsCOGSForDashboard] 

  AS BEGIN
  
  DECLARE @PURCHASE_VALUE AS MONEY, @COGS AS MONEY	, @PERCENTAGE_AVG_PURCHASE_COGS AS VARCHAR(10)
   	
	select @PURCHASE_VALUE = sum(NetAmount) from SCPTnGoodReceiptNote_M where  CreatedDate between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) and IsActive = 1  and IsApproved =1;

	SELECT @COGS=SUM(COGS-COGS_REFUND) FROM
    (
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode
		AND CAST(PD.CreatedDate AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
     )TMP

	SELECT @PERCENTAGE_AVG_PURCHASE_COGS = '1.2%' 

	 SELECT CASE WHEN @COGS!=0 THEN CONVERT(VARCHAR,@COGS/@PURCHASE_VALUE) ELSE CONVERT(VARCHAR,0) END as AVG_PURCHASE_VS_COGS , 
	 @PERCENTAGE_AVG_PURCHASE_COGS AS PERCENTAGE_AVG_PURCHASE_COGS

	 END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptBatchNoOpeningClosing]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptBatchNoOpeningClosing]
@BatchNo AS VARCHAR(50)
AS
BEGIN

	select (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108))
    AS OPNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL 
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_DTL.IsActive=1
	AND SL_MSTR.BatchNo=@BatchNo),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) CSH_SL FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_DTL.IsActive=1
	AND SL_MSTR.BatchNo=@BatchNo),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND RTN_DTL.IsActive=1
	AND RTN_MSTR.BatchNo=@BatchNo),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 AND RTN_DTL.IsActive=1 AND 
	RTN_MSTR.BatchNo=@BatchNo),0) AS CRDT_RTN,
	(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM from SCPTnBatchNo_M
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId 
	WHERE SCPTnBatchNo_M.BatchNo=@BatchNo AND SCPTnBatchNo_M.IsActive=1
	GROUP BY SCPTnBatchNo_M.BatchNo,BatchStartTime, BatchCloseTime,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptBatchNoWisePtCategoyWiseRevenue]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPRptBatchNoWisePtCategoyWiseRevenue]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)

AS BEGIN

SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,SUM(PT_COUNT) AS PT_COUNT,
	  SUM(AMOUNT)-SUM(RefundAmount) AS AMOUNT  FROM
(
	  SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,COUNT(TRANS_ID) AS PT_COUNT,
	  SUM(AMT) AS AMOUNT,0 AS RefundAmount FROM
	(
		SELECT CAST(BB.BatchStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
		PHM.TRANS_ID,SUM(ROUND((Quantity*ItemRate),0)) AS AMT FROM SCPTnSale_M PHM
		INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
		INNER JOIN SCPStPatientCategory CAT ON PatientCategoryId = PatientCategoryId
		INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = CAT.PatientCategoryId AND SB.PatientSubCategoryId = PHM.PatientSubCategoryId
		INNER JOIN SCPTnSale_D PHD ON PARNT_TRANS_ID = PHM.TRANS_ID
		INNER JOIN SCPStUser_M SS ON PHM.CreatedBy = SS.UserId
		WHERE CAST(BB.BatchStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND 
		CAST(CONVERT(date,@ToDate,103) as date)
		GROUP BY CAST(BB.BatchStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
		PHM.TRANS_ID
	)TMP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	UNION ALL
	SELECT CAST(BB.BatchStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName AS PatientCategoryName,
	PatientSubCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = PT_CT.PatientCategoryId AND SB.PatientSubCategoryId = PMM.PatientSubCategoryId
	INNER JOIN SCPStUser_M SS ON PHM.CreatedBy = SS.UserId
	WHERE CAST(BB.BatchStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY CAST(BB.BatchStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	UNION ALL
	SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,0 AS Prescription,0 AS SaleAmount,
	  SUM(ROUND(RefundAmount,0)) AS RefundAmount FROM
	(
		SELECT DISTINCT T_DATE,BatchNo,UserName,PatinetIp,PatientCategoryName,PatientSubCategoryName,ItemCode,RefundAmount FROM
		(
			SELECT CAST(BB.BatchStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PHM.PatinetIp,
			PatientCategoryName AS PatientCategoryName,CASE WHEN PatientTypeId=1 AND PHD.PaymentTermId=2 
			THEN 'OT' ELSE 'Per' END AS PatientSubCategoryName,PHD.ItemCode,ReturnAmount AS RefundAmount
			FROM SCPTnSaleRefund_M PHM 
			INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
			INNER JOIN SCPTnSale_M PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0' 
			INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
			INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID  
			INNER JOIN SCPStUser_M SS ON PHM.CreatedBy = SS.UserId
			WHERE CAST(BB.BatchStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
			AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
		)TMP
	)TMPP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
)TMPP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
ORDER BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
	


--SELECT T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName,COUNT(TRANS_ID) AS PT_COUNT,SUM(AMT) AS AMOUNT FROM
--(
--	SELECT CAST(BB.BatchStartTime AS DATE) T_DATE,PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
--	PHM.TRANS_ID,SUM(ROUND((Quantity*ItemRate),0)) AS AMT FROM SCPTnSale_M PHM
--	INNER JOIN SCPTnBatchNo_M BB ON BB.BatchNo = PHM.BatchNo
--	INNER JOIN SCPStPatientCategory CAT ON PatientCategoryId = PatientCategoryId
--	INNER JOIN SCPStPatientSubCategory SB ON SB.PatientCategoryId = CAT.PatientCategoryId AND SB.PatientSubCategoryId = PHM.PatientSubCategoryId
--	INNER JOIN SCPTnSale_D PHD ON PARNT_TRANS_ID = PHM.TRANS_ID
--	INNER JOIN SCPStUser_M SS ON PHM.CreatedBy = SS.UserId
--	WHERE CAST(BB.BatchStartTime AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
--	AND CAST(CONVERT(date,@ToDate,103) as date)
--	GROUP BY CAST(BB.BatchStartTime AS DATE),PHM.BatchNo,UserName,PatientCategoryName,SB.PatientSubCategoryName,
--	PHM.TRANS_ID
--)TMP GROUP BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName
--ORDER BY T_DATE,BatchNo,UserName,PatientCategoryName,PatientSubCategoryName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCareofSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptCareofSaleSummary]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

  
SELECT TRANS_DT,CareOf, PTName,PatientCategoryName, sum(TotalSale), CareOf , SUM(RTRN_AMOUNT), CASE 
WHEN CareOffCode = 1 THEN (SELECT TOP 1  EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON X.CareOff = EMP.EmployeeCode)
WHEN CareOffCode = 2 THEN (SELECT TOP 1  CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSale_M ON X.CareOff = CONS.ConsultantId)
WHEN CareOffCode = 3 THEN (SELECT  TOP 1  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON X.CareOff = PART.PartnerId)
END AS CAREOF_NM  FROM (

SELECT CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) as TRANS_DT ,SUM(ROUND(Quantity*ItemRate,0)) as TotalSale,CareOffCode,
(CASE WHEN CareOffCode = 1 THEN 'Employee' WHEN CareOffCode=2 THEN 'Consultant' WHEN CareOffCode = 3 THEN 'Partner' END) AS CareOf
	,CareOff
,  (NamePrefix+'. '+FirstName+' '+LastName) as [PTName], PatientCategoryName	 ,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.SaleRefundId = PHM.SaleRefundId 
	 AND PHM.SaleId = SCPTnSale_M.SaleId AND CAST(PHM.SaleRefundDate as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1) AS RTRN_AMOUNT   
			from SCPTnSale_M 
			INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
			INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
			where PatientTypeId= 1 AND SCPTnSale_M.SaleId!='0' AND SCPTnSale_M.PatientIp='0' and SCPTnSale_M.IsActive=1
			GROUP BY  SCPTnSale_M.SaleId ,
			CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) ,CareOffCode, CareOff, NamePrefix, FirstName, LastName, PatientCategoryName
)X
GROUP BY TRANS_DT,CareOf, PTName,PatientCategoryName,CareOf, CareOff, CareOffCode

  UNION ALL 
SELECT TRANS_DT,CareOf, PTName,PatientCategoryName, sum(TotalSale), CareOf , SUM(RTRN_AMOUNT), CASE 
WHEN CareOffCode = 1 THEN (SELECT TOP 1  EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON X.CareOff = EMP.EmployeeCode)
WHEN CareOffCode = 2 THEN (SELECT TOP 1  CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSale_M ON X.CareOff = CONS.ConsultantId)
WHEN CareOffCode = 3 THEN (SELECT  TOP 1  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON X.CareOff = PART.PartnerId)
END AS CAREOF_NM  FROM (

SELECT CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) as TRANS_DT ,SUM(ROUND(Quantity*ItemRate,0))  as TotalSale,CareOffCode,
(CASE WHEN CareOffCode = 1 THEN 'Employee' WHEN CareOffCode=2 THEN 'Consultant' WHEN CareOffCode = 3 THEN 'Partner' END) AS CareOf
	,CareOff
,  (NamePrefix+'. '+FirstName+' '+LastName) as [PTName], PatientCategoryName	 ,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.SaleRefundId = PHM.SaleRefundId 
	 AND PHM.PatinetIp = SCPTnSale_M.PatientIp AND CAST(PHM.SaleRefundDate as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1) AS RTRN_AMOUNT   
			from SCPTnSale_M 
			INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
			INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
			where PatientTypeId= 1  AND SCPTnSale_M.PatientIp !='0' and SCPTnSale_M.IsActive=1
			GROUP BY  SCPTnSale_M.PatientIp ,
			CONVERT(VARCHAR(10), SCPTnSale_M.SaleDate, 105) ,CareOffCode, CareOff, NamePrefix, FirstName, LastName, PatientCategoryName
)X 
GROUP BY TRANS_DT,CareOf, PTName,PatientCategoryName,CareOf, CareOff, CareOffCode
--SELECT sum(ReturnAmount) FROM SCPTnSale_M
--INNER JOIN SCPTnSale_D ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
--INNER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.PatinetIp = SCPTnSale_M.PatientIp
--INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
-- WHERE CAST(SCPTnSaleRefund_M.TRNSCTN_DATE as date)= CAST(CONVERT(date,@FromDate,103) as date) AND PatientCategoryId = 1
-- select sum(ReturnAmount) from SCPTnSaleRefund_M 
-- INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
-- WHERE CAST(SCPTnSaleRefund_M.TRNSCTN_DATE as date) = CAST(CONVERT(date,@ToDate,103) as date)
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptClosingValuation]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptClosingValuation]
@ItemTypeId as INT,
@WraehouseName AS INT,
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN
   
    IF(@ItemTypeId=1)
	BEGIN

	 SELECT * FROM
	(
		SELECT SCPStItem_M.ItemCode,ItemName,'' AS BatchNo,ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance FROM 
	  (SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate desc) AS RN FROM SCPTnStock_D 
	   WHERE ItemCode=SCPStItem_M.ItemCode and WraehouseId=@WraehouseName AND CAST(CreatedDate as date) < CAST(CONVERT(date,@FromDate,103) as date)
	  )TMP WHERE RN = 1)TMP1),0) AS OpeningClose,
		ISNULL((SELECT SUM(RecievedQty) FROM SCPTnGoodReceiptNote_D INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId 
		WHERE WraehouseId=@WraehouseName AND SCPTnGoodReceiptNote_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.IsActive=1 AND SCPTnGoodReceiptNote_M.IsActive=1 and SCPTnGoodReceiptNote_M.IsApproved=1 
		AND CAST(SCPTnGoodReceiptNote_M.CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
		AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RecievedQty,ISNULL((SELECT SUM(IssuedQty) FROM SCPTnIssuance_D 
		INNER JOIN SCPTnIssuance_M ON SCPTnIssuance_D.IssuanceId=SCPTnIssuance_M.IssuanceId	WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(SCPTnIssuance_M.CreatedDate AS DATE)
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS ISSUED_QTY,
		ISNULL((SELECT SUM(ReturnQty) FROM SCPTnGoodReturn_D INNER JOIN SCPTnGoodReturn_M ON SCPTnGoodReturn_D.GoodReturnId=SCPTnGoodReturn_M.GoodReturnId 
		WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(SCPTnGoodReturn_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)  
		AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DEPT_ReturnQty,ISNULL((SELECT SUM(ReturnQty) FROM SCPTnReturnToSupplier_D
		INNER JOIN SCPTnReturnToSupplier_M ON SCPTnReturnToSupplier_D.ReturnToSupplierId = SCPTnReturnToSupplier_M.ReturnToSupplierId WHERE WraehouseId=@WraehouseName AND 
		SCPTnReturnToSupplier_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnReturnToSupplier_D.IsActive=1 AND SCPTnReturnToSupplier_M.IsActive=1 AND CAST(SCPTnReturnToSupplier_M.CreatedDate AS DATE) 
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RTN_SUPLR,
		ISNULL((SELECT SUM(SCPTnItemDiscard_D.DiscardQty) FROM SCPTnItemDiscard_D INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.ItemDiscardId = SCPTnItemDiscard_M.ItemDiscardId 
		WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DISCARD,
		ISNULL((SELECT SUM(CurrentStock-ItemBalance) FROM SCPTnAdjustment_D INNER JOIN SCPTnAdjustment_M ON SCPTnAdjustment_D.AdjustmentId = SCPTnAdjustment_M.AdjustmentId 
		WHERE WraehouseId=@WraehouseName AND SCPTnAdjustment_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnAdjustment_D.IsActive=1 AND SCPTnAdjustment_M.IsActive=1 
		AND CAST(SCPTnAdjustment_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS ADJSTED_QTY,ISNULL((SELECT SUM(BonusQty) FROM SCPTnGoodReceiptNote_D
		INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId WHERE WraehouseId=@WraehouseName AND 
		SCPTnGoodReceiptNote_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.IsActive=1 AND SCPTnGoodReceiptNote_M.IsActive=1 AND CAST(SCPTnGoodReceiptNote_M.CreatedDate AS DATE) 
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS BonusQty,
		ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance FROM (SELECT *,ROW_NUMBER() 
		OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN  FROM SCPTnStock_D WHERE ItemCode= SCPStItem_M.ItemCode and 
		WraehouseId=@WraehouseName AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date))TMP WHERE RN = 1
		)TMP1),0) AS CurrentStock,SCPStRate.CostPrice,(ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance 
		FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN  FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=@WraehouseName 
		AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date))TMP WHERE RN = 1
		)TMP1),0)*SCPStRate.CostPrice) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName
		INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStItem_M.IsActive=1
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStRate.CostPrice 
	)TMP WHERE CurrentStock>0 ORDER BY ItemCode
	END
	ELSE
	BEGIN
	-- SELECT * FROM
	--(
	--   SELECT SCPStItem_M.ItemCode,ItemName,'' AS BatchNo,ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance FROM 
 -- (SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate) AS RN FROM SCPTnStock_D 
 --  WHERE ItemCode=SCPStItem_M.ItemCode and WraehouseId=@WraehouseName AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@FromDate,103) as date)
 -- )TMP WHERE RN = 1)TMP1),0) AS OpeningClose,
	--ISNULL((SELECT SUM(RecievedQty) FROM SCPTnPharmacyIssuance_D INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID = SCPTnPharmacyIssuance_M.TRNSCTN_ID 
	--WHERE WraehouseId=@WraehouseName AND SCPTnPharmacyIssuance_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.IsActive=1 AND SCPTnPharmacyIssuance_M.IsActive=1 
	--AND CAST(SCPTnPharmacyIssuance_M.CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RecievedQty,ISNULL((SELECT SUM(IssueQty) FROM SCPTnPharmacyIssuance_D 
	--INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=SCPTnPharmacyIssuance_M.TRNSCTN_ID WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(SCPTnPharmacyIssuance_M.CreatedDate AS DATE)
	--BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	--AND ToWarehouseId= @WraehouseName),0) AS ISSUED_QTY,
	--ISNULL((SELECT SUM(ReturnQty) FROM SCPTnReturnToStore_D INNER JOIN SCPTnReturnToStore_M ON SCPTnReturnToStore_D.PARENT_TRNSCTN_ID=SCPTnReturnToStore_M.TRNSCTN_ID 
	--WHERE ItemCode=SCPStItem_M.ItemCode and FromWarehouseId=@WraehouseName  AND CAST(SCPTnReturnToStore_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)  
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DEPT_ReturnQty,ISNULL((SELECT SUM(ReturnQty) FROM SCPTnReturnToSupplier_D
	--INNER JOIN SCPTnReturnToSupplier_M ON SCPTnReturnToSupplier_D.PARENT_TRNSCTN_ID = SCPTnReturnToSupplier_M.TRNSCTN_ID WHERE WraehouseId=@WraehouseName AND 
	--SCPTnReturnToSupplier_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnReturnToSupplier_D.IsActive=1 AND SCPTnReturnToSupplier_M.IsActive=1 AND CAST(SCPTnReturnToSupplier_M.CreatedDate AS DATE) 
	--BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RTN_SUPLR,
	--ISNULL((SELECT SUM(SCPTnItemDiscard_D.Quantity) FROM SCPTnItemDiscard_D INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID 
	--WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
	--BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DISCARD,
	--ISNULL((SELECT SUM(CurrentStock-ItemBalance) FROM SCPTnAdjustment_D INNER JOIN SCPTnAdjustment_M ON SCPTnAdjustment_D.PARENT_TRNSCTN_ID = SCPTnAdjustment_M.TRNSCTN_ID 
	--WHERE WraehouseId=@WraehouseName AND SCPTnAdjustment_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnAdjustment_D.IsActive=1 AND SCPTnAdjustment_M.IsActive=1 
	--AND CAST(SCPTnAdjustment_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS ADJSTED_QTY,ISNULL((SELECT SUM(BonusQty) FROM SCPTnPharmacyIssuance_D
	--INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID = SCPTnPharmacyIssuance_M.TRNSCTN_ID WHERE WraehouseId=@WraehouseName AND 
	--SCPTnPharmacyIssuance_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.IsActive=1 AND SCPTnPharmacyIssuance_M.IsActive=1 AND CAST(SCPTnPharmacyIssuance_M.CreatedDate AS DATE) 
	--BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS BonusQty,
	--ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance FROM (SELECT *,ROW_NUMBER() 
	--OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN  FROM SCPTnStock_D WHERE ItemCode= SCPStItem_M.ItemCode and 
	--WraehouseId=@WraehouseName AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date))TMP WHERE RN = 1
 --   )TMP1),0) AS CurrentStock,SCPStRate.CostPrice,(ISNULL((SELECT SUM(ItemBalance) FROM (SELECT BatchNo,ItemBalance 
	--FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN  FROM SCPTnStock_D 
	--WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=@WraehouseName 
	--AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date))TMP WHERE RN = 1
 --   )TMP1),0)*SCPStRate.CostPrice) AS STOCK_VALUE FROM SCPStItem_M
	--INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName
	--INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	--FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
	--GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStRate.CostPrice ORDER BY SCPStItem_M.ItemCode

		  SELECT SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.BatchNo,ISNULL((SELECT TOP 1 SCPTnStock_D.ItemBalance FROM SCPTnStock_D 
		WHERE ItemCode= SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName AND BatchNo=SCPTnStock_M.BatchNo
		AND CAST(CreatedDate as date) < CAST(CONVERT(date,@FromDate,103) as date) ORDER BY CreatedDate desc),0) AS OpeningClose,
		ISNULL((SELECT SUM(RecievedQty) FROM SCPTnGoodReceiptNote_D INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId 
		WHERE WraehouseId=@WraehouseName AND SCPTnGoodReceiptNote_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo AND SCPTnGoodReceiptNote_D.IsActive=1 
		AND SCPTnGoodReceiptNote_M.IsActive=1 and SCPTnGoodReceiptNote_M.IsApproved=1 AND CAST(SCPTnGoodReceiptNote_M.CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
		AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RecievedQty,ISNULL((SELECT SUM(SCPTnStock_D.StockQuantity) FROM SCPTnPharmacyIssuance_D 
		INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PharmacyIssuanceId=SCPTnPharmacyIssuance_M.PharmacyIssuanceId 
		INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = SCPTnPharmacyIssuance_D.PharmacyIssuanceId AND SCPTnStock_D.ItemCode=SCPTnPharmacyIssuance_D.ItemCode
		WHERE SCPTnPharmacyIssuance_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnStock_D.BatchNo=SCPTnStock_M.BatchNo AND CAST(SCPTnPharmacyIssuance_M.CreatedDate AS DATE)
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) --AND ToWarehouseId= @WraehouseName 
		AND SCPTnStock_D.WraehouseId=@WraehouseName),0) AS ISSUED_QTY, ISNULL((SELECT SUM(ReturnQty) FROM SCPTnReturnToStore_D INNER JOIN SCPTnReturnToStore_M ON 
		SCPTnReturnToStore_D.ReturnToStoreId=SCPTnReturnToStore_M.ReturnToStoreId WHERE ItemCode=SCPStItem_M.ItemCode and FromWarehouseId=@WraehouseName AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(SCPTnReturnToStore_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DEPT_ReturnQty,
		ISNULL((SELECT SUM(ReturnQty) FROM SCPTnReturnToSupplier_D INNER JOIN SCPTnReturnToSupplier_M ON SCPTnReturnToSupplier_D.ReturnToSupplierId = SCPTnReturnToSupplier_M.ReturnToSupplierId 
		WHERE WraehouseId=@WraehouseName AND SCPTnReturnToSupplier_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnReturnToSupplier_D.BatchNo=SCPTnStock_M.BatchNo AND SCPTnReturnToSupplier_D.IsActive=1 AND
		SCPTnReturnToSupplier_M.IsActive=1 AND CAST(SCPTnReturnToSupplier_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS RTN_SUPLR,ISNULL((SELECT SUM(SCPTnItemDiscard_D.DiscardQty) FROM SCPTnItemDiscard_D 
		INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.ItemDiscardId = SCPTnItemDiscard_M.ItemDiscardId WHERE ItemCode=SCPStItem_M.ItemCode AND 
		SCPTnItemDiscard_D.BatchNo=SCPTnStock_M.BatchNo AND WraehouseId=@WraehouseName AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE) BETWEEN 
		CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DISCARD,
		ISNULL((SELECT SUM(CurrentStock-ItemBalance) FROM SCPTnAdjustment_D INNER JOIN SCPTnAdjustment_M ON SCPTnAdjustment_D.AdjustmentId = SCPTnAdjustment_M.AdjustmentId 
		WHERE WraehouseId=@WraehouseName AND SCPTnAdjustment_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnAdjustment_D.IsActive=1 AND SCPTnAdjustment_M.IsActive=1 
		AND CAST(SCPTnAdjustment_M.CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND 
		CAST(CONVERT(date,@ToDate,103) as date)),0) AS ADJSTED_QTY,ISNULL((SELECT SUM(BonusQty) FROM SCPTnGoodReceiptNote_D
		INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId WHERE WraehouseId=@WraehouseName AND SCPTnGoodReceiptNote_D.ItemCode=SCPStItem_M.ItemCode 
		AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo AND SCPTnGoodReceiptNote_D.IsActive=1 AND SCPTnGoodReceiptNote_M.IsActive=1 AND CAST(SCPTnGoodReceiptNote_M.CreatedDate AS DATE) 
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS BonusQty,
		ISNULL((SELECT TOP 1 ItemBalance FROM SCPTnStock_D WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=@WraehouseName AND BatchNo=SCPTnStock_M.BatchNo
		AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date) ORDER BY CreatedDate DESC),0) AS CurrentStock,
		isnull(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END,0) AS CostPrice,(ISNULL((SELECT TOP 1 
		ItemBalance FROM SCPTnStock_D WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=@WraehouseName AND BatchNo=SCPTnStock_M.BatchNo 
		AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date) ORDER BY CreatedDate DESC),0)*(CASE WHEN 
		SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=@WraehouseName
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteId FROM SCPTnGoodReceiptNote_D WHERE SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode 
		                          AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
   		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
		--WHERE SCPStItem_M.IsActive=1  
		WHERE SCPTnStock_M.CurrentStock>0 
		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate 
		ORDER BY SCPStItem_M.ItemCode
	--)TMP WHERE CurrentStock>0 
	--ORDER BY ItemCode
	END
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptConsultantWiseInventory]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPRptConsultantWiseInventory]

AS BEGIN

	SELECT MemberName,0 NoOfPts,COUNT(Items) Items,SUM(POS_MEAN_VAL+MSS_MEAN_VAL) Invntry,1.2 Stndrd,
	CASE WHEN SUM(POS_MEAN_VAL+MSS_MEAN_VAL)=0 AND SUM(Sales)!=0 THEN 0 WHEN SUM(Sales)=0 THEN 1 
	ELSE (SUM(Sales))/SUM(POS_MEAN_VAL+MSS_MEAN_VAL) END AS SalesRatio FROM
	(
		SELECT MemberName,Items,Sales,(CAST(ROUND(CAST(SUM(MinLevel)+SUM(MaxLevel) AS FLOAT)/2,0) AS INT)
		*CostPrice) AS POS_MEAN_VAL,(CAST(ROUND(CAST(SUM(MSS_MinLevel)+SUM(MSS_MaxLevel) AS FLOAT)/2,0) AS INT)
		*CostPrice) AS MSS_MEAN_VAL FROM
		(
			SELECT CASE WHEN RC.ConsultantId IS NULL THEN RC.RecommendedMemberName ELSE CON.ConsultantName END AS MemberName,
			ISNULL(OP.PatientCount,0) NoOfPts,ISNULL(CASE WHEN SCPStParLevelAssignment_D.ParLevelId=14 THEN SCPStParLevelAssignment_D.NewLevel END,0) AS MinLevel,
			ISNULL(CASE WHEN SCPStParLevelAssignment_D.ParLevelId=16 THEN SCPStParLevelAssignment_D.NewLevel END,0) AS MaxLevel,CostPrice,CC.ItemCode AS Items,
			ISNULL((SELECT SUM(ROUND(Quantity*ItemRate,0)) FROM SCPTnSale_D PHD WHERE PHD.ItemCode=CC.ItemCode AND 
			CAST(PHD.CreatedDate AS DATE) BETWEEN DATEADD(DAY,-30, GETDATE()) AND GETDATE()),0) Sales,
			ISNULL(CASE WHEN ccd.ParLevelId=14 THEN ccd.NewLevel END,0) AS MSS_MinLevel,
			ISNULL(CASE WHEN ccd.ParLevelId=16 THEN ccd.NewLevel END,0) AS MSS_MaxLevel FROM SCPStItem_M CC
			INNER JOIN SCPStItem_M_RecommendationApproval REC ON REC.ItemCode = CC.ItemCode
			INNER JOIN SCPStRecommendedBy RC ON RC.RecommendedMemberId = REC.RecommendedMemberId
			INNER JOIN SCPStConsultant CON ON CON.ConsultantId = RC.ConsultantId
			LEFT OUTER JOIN SCPTnOPDPatient OP ON OP.ConsultantId = CON.ConsultantId 
			AND CAST(OP.DataDate AS DATE) = CAST(DATEADD(D,-1,GETDATE()) AS DATE)
			INNER JOIN SCPStParLevelAssignment_M ON CC.ItemCode = SCPStParLevelAssignment_M.ItemCode
			INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN(14,16)	AND 
			SCPStParLevelAssignment_M.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=3)
			INNER JOIN SCPStParLevelAssignment_M ccm ON CC.ItemCode = ccm.ItemCode
			INNER JOIN SCPStParLevelAssignment_D ccd ON ccd.ParLevelAssignmentId = ccm.ParLevelAssignmentId AND ccd.ParLevelId IN(14,16)	AND 
			ccm.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=10)
			INNER JOIN SCPStRate ON CC.ItemCode = SCPStRate.ItemCode
			AND SCPStRate.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
			WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=CC.ItemCode)
		)TMP#0 GROUP BY  MemberName,Items,Sales,CostPrice 
	)TMP#1 GROUP BY MemberName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCorpPatientSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptCorpPatientSaleSummary]
@Data_DT AS VARCHAR(50)
AS
BEGIN
    SELECT DISTINCT SCPTnSale_M.PatientIp,(PT.NamePrefix+'. '+PT.FirstName+' '+PT.LastName) AS SCPTnInPatient_NAME,
	CompanyName,(ISNULL((SELECT SUM(ROUND(Quantity*DD.ItemRate,0)) FROM SCPTnSale_D DD
	INNER JOIN SCPTnSale_M MM ON MM.SaleId = DD.SaleId 
	AND MM.PatientIp=SCPTnSale_M.PatientIp AND CAST(MM.CreatedDate AS date)<CAST(CONVERT(date,@Data_DT,103) as date)),0)-
	ISNULL((SELECT SUM(ROUND(ReturnQty*ItemRate,0)) FROM SCPTnSaleRefund_D DD
	INNER JOIN SCPTnSaleRefund_M MM ON MM.SaleRefundId = DD.SaleRefundId 
	AND MM.PatinetIp=SCPTnSale_M.PatientIp AND CAST(MM.CreatedDate AS date)<
	CAST(CONVERT(date,@Data_DT,103) as date)),0)) AS PREVIOUS_AMT,
	(SUM(ROUND(Quantity*ItemRate,0))-ISNULL((SELECT SUM(ROUND(ReturnQty*ItemRate,0)) FROM SCPTnSaleRefund_D DD
	INNER JOIN SCPTnSaleRefund_M MM ON MM.SaleRefundId = DD.SaleRefundId 
	AND MM.PatinetIp=SCPTnSale_M.PatientIp AND CAST(MM.CreatedDate AS date)=
	CAST(CONVERT(date,@Data_DT,103) as date)),0)) AS CURRENT_AMT FROM SCPTnSale_M
	INNER JOIN SCPTnInPatient PT ON PT.PatientIp = SCPTnSale_M.PatientIp
	INNER JOIN SCPStCompany ON PT.CompanyId = SCPStCompany.CompanyId
	INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
	WHERE CAST(SCPTnSale_M.CreatedDate AS date)=CAST(CONVERT(date,@Data_DT,103) as date) AND SCPTnSale_M.PatientTypeId=2
	GROUP BY SCPTnSale_M.PatientIp,(PT.NamePrefix+'. '+PT.FirstName+' '+PT.LastName),CompanyName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCounterWisePharmacySaleReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptCounterWisePharmacySaleReport]
@FromDate varchar(50),
@ToDate varchar(50)

AS BEGIN

SELECT PHB.BatchNo,PHB.BatchStartTime,PHB.BatchCloseTime,SI.CounterName,PatientCategoryName,SUM(Prescription) AS Prescription,SUM(SaleAmount)-SUM(RefundAmount) AS Amount FROM
(
	SELECT PHM.BatchNo,PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,
	SUM(ROUND(ReturnAmount,0))  AS RefundAmount	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	INNER JOIN SCPTnSale_M PMM ON PHM.SaleId = PMM.SaleId  AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY PHM.BatchNo,PatientCategoryName
	UNION ALL
	SELECT PHM.BatchNo,PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,
	SUM(ROUND(ReturnAmount,0))  AS RefundAmount	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY PHM.BatchNo,PatientCategoryName
	UNION ALL
	SELECT  BatchNo,PT_CT.PatientCategoryName  AS PatientCategoryName,COUNT(X.Prescription) AS Prescription,
	SUM(X.Amount) AS SaleAmount,0 AS RefundAmount 
	FROM(
		SELECT PHM.BatchNo,PHM.SaleId AS Prescription,SUM(ROUND(Quantity*ITemRate,0))  AS Amount, 
		PHM.PatientCategoryId AS PatientCategoryId FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.SaleId = PHD.SaleId
		WHERE CAST(PHM.SaleDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
		GROUP BY PHM.BatchNo,PHM.SaleId, PHM.PatientCategoryId
		)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
		   GROUP BY BatchNo,PT_CT.PatientCategoryName
	)TMP INNER JOIN SCPTnBatch_M PHB ON PHB.BatchNo = TMP.BatchNo
	LEFT OUTER JOIN SCPStSystemInformation SI ON PHB.TerminalName = SI.IpAddress
	--LEFT OUTER JOIN SCPStSystemInformation SS ON PHB.TerminalName = SI.SystemName
GROUP BY SI.CounterName,PHB.BatchNo,PHB.BatchStartTime,PHB.BatchCloseTime,PatientCategoryName
ORDER BY PHB.BatchStartTime,SI.CounterName,PatientCategoryName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptCriticalParLevel]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptCriticalParLevel]
AS
BEGIN
	SELECT ItemCode,ItemName,GRN_DATE,PO_DATE,SUP_NM,ISNULL(DAYS_DIF,0) AS DAYS_DIF,
	CASE WHEN AVG_TRND BETWEEN 0 AND 15 THEN 'DEAD' WHEN AVG_TRND BETWEEN 15 AND 50 THEN 'LOW' 
    WHEN AVG_TRND BETWEEN 50 AND 100 THEN 'AVG' ELSE 'HIGH' END AS ITM_SL_TRND FROM  
   (
    SELECT ItemCode,ItemName,DATEDIFF(DAY,STOCK_DT,GETDATE()) AS DAYS_DIF,CASE WHEN DAILY_SALE!=0 AND AvgPerDay!=0 
	THEN CAST(CAST(DAILY_SALE AS decimal)/CAST(AvgPerDay AS decimal) AS decimal(2))*100 
	WHEN DAILY_SALE!=0 AND AvgPerDay=0 THEN DAILY_SALE*100 ELSE 0 END AS AVG_TRND,GRN_DATE,PO_DATE,SUP_NM FROM
	(
	 SELECT SCPStItem_M.ItemCode,ItemName, SUM(CurrentStock) AS CurrentStock,NewLevel,ISNULL(SCPStParLevelAssignment_M.AvgPerDay,0) AS AvgPerDay,
	 CASE WHEN MAX(SCPTnStock_M.EditedDate) IS NULL THEN MAX(SCPTnStock_M.CreatedDate) ELSE MAX(SCPTnSEditedDatetock_M.) END AS STOCK_DT,
	 ISNULL((SELECT (SUM(Quantity)/90) AS SALES FROM SCPTnSale_D WHERE CreatedDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()
	 AND ItemCode=SCPStItem_M.ItemCode),0) AS DAILY_SALE,(SELECT GoodReceiptNoteDate FROM SCPTnGoodReceiptNote_M WHERE GoodReceiptNoteId=(SELECT TOP 1 GoodReceiptNoteId 
	 FROM SCPTnGoodReceiptNote_D WHERE ItemCode=SCPStItem_M.ItemCode ORDER BY SCPTnGoodReceiptNote_D.CreatedDate DESC)) AS GRN_DATE,(SELECT SCPTnPurchaseOrder_M.PurchaseOrderDate FROM SCPTnPurchaseOrder_M 
	 WHERE PurchaseOrderId=(SELECT TOP 1 SCPTnPurchaseOrder_D.PurchaseOrderId FROM SCPTnPurchaseOrder_D WHERE ItemCode=SCPStItem_M.ItemCode ORDER BY SCPTnPurchaseOrder_D.CreatedDate DESC)) AS PO_DATE,
	 (SELECT SupplierLongName FROM SCPTnPurchaseOrder_M INNER JOIN SCPStSupplier ON SCPTnPurchaseOrder_M.SupplierId = SCPStSupplier.SupplierId WHERE PurchaseOrderId=(SELECT TOP 1 SCPTnPurchaseOrder_D.PurchaseOrderId 
	 FROM SCPTnPurchaseOrder_D WHERE ItemCode=SCPStItem_M.ItemCode  ORDER BY SCPTnPurchaseOrder_D.CreatedDate DESC)) AS SUP_NM FROM SCPStItem_M
     INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT TOP 1 CPM.ParLevelAssignmentId 
     FROM SCPStParLevelAssignment_M CPM WHERE CPM.ItemCode=SCPStItem_M.ItemCode AND WraehouseId=10 ORDER BY CPM.CreatedDate DESC)
     INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_M.ParLevelAssignmentId = SCPStParLevelAssignment_D.ParLevelAssignmentId AND ParLevelId=13 AND SCPStParLevelAssignment_M.WraehouseId=10 
     INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND ItemTypeId=2 AND SCPTnStock_M.WraehouseId=10
	 WHERE SCPStItem_M.IsActive=1
     GROUP BY SCPStItem_M.ItemCode,ItemName,NewLevel,AvgPerDay HAVING SUM(CurrentStock)<=NewLevel and SUM(CurrentStock)!=0
	 )TMP
	)TMPP ORDER BY DAYS_DIF
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDeadStock]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptDeadStock]
@WraehouseId AS INT

AS BEGIN
SELECT TMPPPP.ItemCode,ItemName,CurrentStock,CostPrice,CurrentStock*CostPrice AS VALUATION,MemberName FROM
(
	SELECT TMPPP.ItemCode,ItemName,CurrentStock,CostPrice,MemberName,
	CASE WHEN AvgPerDay=0 AND AVG_SALE=0 THEN 0 WHEN AvgPerDay=0 THEN AVG_SALE*100 
	ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM	
	(
		SELECT TMPP.ItemCode,ItemName,AvgPerDay,TMPP.CurrentStock,CostPrice,MemberName,
		ROUND(CAST(ISNULL(SUM(Quantity),0) AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()),0) AS AVG_SALE FROM
		(
			SELECT SCPStItem_M.ItemCode,ItemName,AvgPerDay,PRIC.CostPrice, 
			CASE WHEN RC.ConsultantId IS NULL THEN RC.RecommendedMemberName ELSE CON.ConsultantName END AS MemberName,
			SUM(STCK.CurrentStock) AS CurrentStock FROM SCPStItem_M
			LEFT OUTER JOIN SCPStItem_M_RecommendationApproval REC ON REC.ItemCode = SCPStItem_M.ItemCode
			LEFT OUTER JOIN SCPStRecommendedBy RC ON RC.RecommendedMemberId = REC.RecommendedMemberId
			LEFT OUTER JOIN SCPStConsultant CON ON CON.ConsultantId = RC.ConsultantId
			INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
			INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId=@WraehouseId
			INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
			INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
			AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1) and SCPStItem_M.IsActive=1 
			GROUP BY SCPStItem_M.ItemCode,ItemName,PRIC.CostPrice,AvgPerDay,RC.ConsultantId,RC.RecommendedMemberName,CON.ConsultantName
		)TMPP 
		LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = TMPP.ItemCode
		AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
		GROUP BY TMPP.ItemCode,ItemName,AvgPerDay,TMPP.CurrentStock,CostPrice,MemberName
	)TMPPP
)TMPPPP,SCPStStockConsumptionType CT 
WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo AND ItemConsumptionIdTypeId=4 ORDER BY VALUATION DESC
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDepartmentWiseRefund]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptDepartmentWiseSaleRefund]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
	SELECT PC.PatientCategoryName AS PatientCategory,
		   SaleM.FirstName AS SCPTnInPatientName,
		   PSC.PatientSubCategoryName AS PatientSubCategory,
		   RefundM.SaleId AS SaleInvoice,
		   RefundM.CreatedDate AS CreatedOn,
		   SCPStUser_M.UserName AS UserId,
		   ItemM.ItemName AS ItemDesciption,
		   SaleM.PatientIp AS PatientIp,
		   Dose.DosageName AS DoseName,
		   SUM(RefundD.ReturnQty) AS ReturnQty,
		   SUM(RefundD.ReturnAmount) AS RefundAmount
	FROM [dbo].[SCPStPatientCategory] AS PC 
	INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
	INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON PSC.PatientSubCategoryId = SaleM.PatientSubCategoryId
	INNER JOIN [dbo].[SCPTnSaleRefund_M] AS RefundM On SaleM.SaleId = RefundM.SaleId
	INNER JOIN [dbo].[SCPTnSaleRefund_D] AS RefundD ON RefundM.SaleRefundId = RefundD.SaleRefundId
	INNER JOIN [dbo].[SCPStItem_M] AS ItemM On RefundD.ItemCode = ItemM.ItemCode
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = RefundM.CreatedBy
	LEFT JOIN [dbo].[SCPStDosage] AS Dose ON Dose.DosageId = ItemM.DosageFormId
	WHERE RefundM.PatinetIp = '0'  and RefundM.IsActive=1 AND 
		  CAST(RefundM.CreatedDate as date) BETWEEN 
		  CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
	GROUP BY  PC.PatientCategoryName,
			  SaleM.FirstName,
			  PSC.PatientSubCategoryName,
			  RefundM.SaleId,
			  RefundM.CreatedDate,
			  ItemM.ItemName,
			  SaleM.PatientIp,
			  Dose.DosageName,
			  SCPStUser_M.UserName

	UNION ALL

	SELECT PC.PatientCategoryName AS PatientCategory,
		   SaleM.FirstName AS SCPTnInPatientName,
		   PSC.PatientSubCategoryName AS PatientSubCategory,
		   RefundM.SaleId AS SaleInvoice,
		   RefundM.CreatedDate AS CreatedOn,
		   SCPStUser_M.UserName AS UserId,
		   ItemM.ItemName AS ItemDesciption,
		   SaleM.PatientIp AS PatientIp,
		   Dose.DosageName AS DoseName,
		   SUM(RefundD.ReturnQty) AS ReturnQty,
		   SUM(RefundD.ReturnAmount) AS RefundAmount
	FROM [dbo].[SCPStPatientCategory] AS PC 
	INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
	INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON PSC.PatientSubCategoryId = SaleM.PatientSubCategoryId
	INNER JOIN [dbo].[SCPTnSaleRefund_M] AS RefundM On SaleM.PatientIp = RefundM.PatinetIp
	INNER JOIN [dbo].[SCPTnSaleRefund_D] AS RefundD ON RefundM.SaleRefundId = RefundD.SaleRefundId
	INNER JOIN [dbo].[SCPStItem_M] AS ItemM On RefundD.ItemCode = ItemM.ItemCode
	LEFT JOIN [dbo].[SCPStDosage] AS Dose ON Dose.DosageId = ItemM.DosageFormId
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = RefundM.CreatedBy
	where RefundM.SaleRefundId = '0' AND RefundM.IsActive=1 AND
		  CAST(RefundM.CreatedDate as date) BETWEEN 
		  CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
	GROUP BY  PC.PatientCategoryName,
			  SaleM.FirstName,
			  PSC.PatientSubCategoryName,
			  RefundM.SaleId,
			  RefundM.CreatedDate,
			  ItemM.ItemName,
			  SaleM.PatientIp,
			  Dose.DosageName,
			  SCPStUser_M.UserName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDeptWiseSale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptDeptWiseSale]

@paramFormDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
	WITH CTE_Dept_Wise_Sale(PatientCategory,
				            SCPTnInPatientTypeName,
							PatientSubCategory,
							TotalQty,
							Sale,
							RefundAmount,
							CreatedOn)
	AS
	(	SELECT PC.PatientCategoryName AS PatientCategory,
			   SCPTnInPatientType.PatientTypeName  AS SCPTnInPatientTypeName,
			   PSC.PatientSubCategoryName AS PatientSubCategory,
			   SUM(SaleD.Quantity) TotalQty,
			   SUM(ROUND(SaleD.Quantity*SaleD.ItemRate,0)) AS Sale,
			   ISNULL(SUM(ReturnD.ReturnAmount),0) AS RefundAmount,
			   SaleM.CreatedDate AS CreatedOn
		FROM [dbo].[SCPStPatientCategory] AS PC 
		INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
		INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON PSC.PatientSubCategoryId = SaleM.PatientSubCategoryId
		INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = SaleM.PatientTypeId
		INNER JOIN [dbo].SCPTnSale_D AS SaleD On SaleD.SaleId = SaleM.SaleId
		LEFT JOIN [dbo].SCPTnSaleRefund_M AS ReturnM ON ReturnM.SaleRefundId = SaleD.SaleId
		LEFT JOIN [dbo].[SCPTnSaleRefund_D] AS ReturnD ON ReturnM.SaleRefundId = ReturnD.SaleRefundId
		WHERE CAST(SaleM.CreatedDate as date) 
				 BETWEEN CAST(CONVERT(date,@paramFormDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
				 AND SaleM.IsActive=1 AND ReturnM.IsActive=1   
		GROUP BY PC.PatientCategoryName,
			     SCPTnInPatientType.PatientTypeName,
				 PSC.PatientSubCategoryName,
				 SaleM.CreatedDate
	
	
	)
SELECT PatientCategory,
	   SCPTnInPatientTypeName,
	   PatientSubCategory,
	   TotalQty,
	   Sale,
	   RefundAmount,
	   CreatedOn,
	   (SELECT SUM(ROUND(Quantity*SaleD.ItemRate,0))  AS TotalSum
		FROM [dbo].[SCPStPatientCategory] AS PC 
		INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
		INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON PSC.PatientSubCategoryId = SaleM.PatientSubCategoryId
		INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = SaleM.PatientTypeId
		INNER JOIN [dbo].SCPTnSale_D AS SaleD On SaleD.SaleId = SaleM.SaleId
		LEFT JOIN [dbo].SCPTnSaleRefund_M AS ReturnM ON ReturnM.SaleId = SaleD.SaleId
		LEFT JOIN [dbo].[SCPTnSaleRefund_D] AS ReturnD ON ReturnM.SaleRefundId = ReturnD.SaleRefundId) AS TotalSum,
	   CONCAT((Sale/(SELECT SUM(Saled.Amount) AS TotalSum
		FROM [dbo].[SCPStPatientCategory] AS PC 
		INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
		INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON PSC.PatientSubCategoryId = SaleM.PatientSubCategoryId
		INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = SaleM.PatientTypeId
		INNER JOIN [dbo].SCPTnSale_D AS SaleD On SaleD.SaleId = SaleM.SaleId
		LEFT JOIN [dbo].SCPTnSaleRefund_M AS ReturnM ON ReturnM.SaleId = SaleD.SaleId
		LEFT JOIN [dbo].[SCPTnSaleRefund_D] AS ReturnD ON ReturnM.SaleRefundId = ReturnD.SaleRefundId))*100,'%') AS Percentage
FROM CTE_Dept_Wise_Sale

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDetailItemDiscountBySupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptDetailItemDiscountBySupplier]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50)
AS
BEGIN

 SELECT SupplierLongName AS SupplierName,TTL_ITM AS TotalItem,TotalAmount AS TotalPurchase,Discount_ITM AS NumberOfDiscountItem,
 Discount_VAL AS DiscountValue,(TTL_ITM-Discount_ITM) AS NumberOfNotDiscountItem,
 CONVERT(varchar,ISNULL((Discount_VAL*100)/TotalAmount,0)) AS PercentageOfDiscountValue FROM 
  (
  SELECT SCPStSupplier.SupplierLongName,COUNT(ItemCode) TTL_ITM,SUM(SCPTnGoodReceiptNote_D.NetAmount) AS TotalAmount,(SELECT COUNT(PRCD.ItemCode) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteId = PRCM.GoodReceiptNoteId WHERE PRCD.DiscountValue!=0 
  AND PRCM.SupplierId=SCPTnGoodReceiptNote_M.SupplierId AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)) AS Discount_ITM,
  (SELECT SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*PRCD.TotalAmount) END) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.GoodReceiptNoteId = PRCM.GoodReceiptNoteId WHERE PRCD.DiscountValue!=0 
  AND PRCM.SupplierId=SCPTnGoodReceiptNote_M.SupplierId AND cast(PRCM.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
  AND CAST(CONVERT(date,@paramToDate,103) as date)) AS Discount_VAL FROM SCPTnGoodReceiptNote_D
  INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
  INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId
  WHERE SCPStSupplier.ItemTypeId=@paramItemTypeId AND cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date) 
  BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
  GROUP BY SCPTnGoodReceiptNote_M.SupplierId,SCPStSupplier.SupplierLongName
   )TMP


--WITH CTE_DetailItemDiscountBySupplier(SupplierName, 
--									  TotalItem,
--									  TotalPurchase,
--									  DiscountValue,
--									  NumberOfNotDiscountItem,
--									  NumberOfDiscountItem
--									  )
--AS
--(	
--	SELECT  Supplier.SupplierLongName AS SupplierName,
--			SUM(ItemPurchaseD.RecievedQty) AS TotalItem,
--			SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
--			SUM(ItemPurchaseD.TotalAmount - ItemPurchaseD.AfterDiscountAmount) DiscountValue ,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
--			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
--	FROM  [dbo].[SCPStSupplier] AS Supplier 
--	INNER JOIN [dbo].[SCPTnPharmacyIssuance_M] AS ItemPurchaseM ON ItemPurchaseM.SupplierId = Supplier.SupplierId
--	INNER JOIN [dbo].[SCPTnPharmacyIssuance_D] AS ItemPurchaseD ON ItemPurchaseM.TRNSCTN_ID = ItemPurchaseD.PARENT_TRNSCTN_ID
--	--INNER JOIN [dbo].[SCPStItem_M] AS ItemManufacture ON ItemPurchaseD.ItemCode = ItemManufacture.ItemCode
--	WHERE Supplier.ItemTypeId = @paramItemTypeId AND
--		  CAST(ItemPurchaseM.CreatedDate as date) BETWEEN 
--		  CAST(CONVERT(date,@paramFromDate,103) as date) AND
--		  CAST(CONVERT(date,@paramToDate,103) as date)  
--	GROUP BY Supplier.SupplierLongName
--)

--SELECT SupplierName, 
--	   ISNULL(TotalItem,0) AS TotalItem,
--	   ISNULL(TotalPurchase,0) AS TotalPurchase,
--	   ISNULL(DiscountValue,0) AS DiscountValue,
--	   ISNULL(NumberOfDiscountItem,0) AS NumberOfDiscountItem,
--	   ISNULL(NumberOfNotDiscountItem,0) AS NumberOfNotDiscountItem,
--	   CONVERT(varchar,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))	 AS PercentageOfDiscountValue
--FROM CTE_DetailItemDiscountBySupplier
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDetailItemReturnToDeparment]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptDetailItemReturnToDeparment]
@paramWraehouseId BIGINT,
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
		SELECT ItemM.ItemCode AS ItemCode,
			   ItemM.ItemName AS Descriptions,
			   Department.DepartmentName AS Department,
			   GRD.GoodReturnId AS TransectionId,
			    GRM.CreatedDate as CreatedOn,
			   CurrentItemPrice.CostPrice AS PurhcasePrice,
			   ReasonId.ReasonId AS ReasonId,
			   SUM(GRD.ReturnQty) AS ReturnQty
	  
		FROM [dbo].[SCPTnGoodReturn_M] AS GRM
		INNER JOIN [dbo].[SCPStDepartment] AS Department ON GRM.DepartmentId = Department.DepartmentId
		INNER JOIN [dbo].[SCPTnGoodReturn_D] AS GRD ON GRM.GoodReturnId = GRD.GoodReturnId
		INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON GRD.ItemCode = ItemM.ItemCode
		INNER JOIN [dbo].[SCPStRate] AS CurrentItemPrice On CurrentItemPrice.ItemCode = ItemM.ItemCode
		AND GETDATE() BETWEEN CurrentItemPrice.FromDate AND CurrentItemPrice.ToDate
		INNER JOIN [dbo].[SCPStReasonId] AS ReasonId ON GRD.ReturnReasonIdId = ReasonId.ReasonId
		WHERE GRM.WarehouseId =@paramWraehouseId AND 
		Cast(ItemM.CreatedDate as date) BETWEEN 
		CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date) 
		GROUP BY 
			   ItemM.ItemCode,
			   ItemM.ItemName ,
			   Department.DepartmentName,
			   GRD.GoodReturnId,
			   GRM.CreatedDate,
			   CurrentItemPrice.CostPrice,
			   ReasonId.ReasonId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardIndentDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptDiscardIndentDetail]
@IndentDiscardNo as VARCHAR(50)
AS
BEGIN
	SELECT DISTINCT SCPTnIndent_D.IndentId,SCPTnIndent_D.ItemCode,SCPStItem_M.ItemName,
   SCPTnIndent_D.RequestedQty,SCPTnIndent_D.PendingQty,SCPTnIndent_D.DiscardQty,
   CASE WHEN ReasonId IS NULL THEN DiscardReasonId ELSE ReasonId END AS ReasonId FROM SCPTnIndent_D
   INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnIndent_D.ItemCode
   INNER JOIN SCPTnIndentDiscard_M ON SCPTnIndentDiscard_M.IndentId = SCPTnIndent_D.IndentId
   INNER JOIN SCPTnIndentDiscard_D ON SCPTnIndentDiscard_M.IndentDiscardId = SCPTnIndentDiscard_D.IndentDiscardId AND SCPTnIndent_D.ItemCode=SCPTnIndentDiscard_D.ItemCode
   LEFT OUTER JOIN SCPStReasonId ON SCPStReasonId.ReasonId = SCPTnIndentDiscard_D.DiscardReasonId
   WHERE SCPTnIndent_D.IndentId=@IndentDiscardNo AND SCPTnIndent_D.DiscardQty>0
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardIndentMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPRptDiscardIndentMaster]
@IndentDiscardNo as VARCHAR(50)
AS
BEGIN
	SELECT IndentDiscardId,SCPTnIndentDiscard_M.DiscardDate,DepartmentName FROM SCPTnIndentDiscard_M
    INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId = SCPTnIndentDiscard_M.DepartmentId
    WHERE IndentDiscardId=@IndentDiscardNo
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardPODetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDiscardPODetail]
@PurchaseOrderId as VARCHAR(50)
AS
BEGIN
	SELECT DISTINCT SCPTnPurchaseOrder_D.PurchaseOrderId,SCPTnPurchaseOrder_D.ItemCode,ItemName,SCPTnPurchaseOrder_D.OrderQty,SCPTnPurchaseOrder_D.PendingQty,SCPTnPurchaseOrder_D.DiscardQty,
    CASE WHEN ReasonId IS NULL THEN DiscardReasonId ELSE ReasonId END AS ReasonId FROM SCPTnPurchaseOrder_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
    INNER JOIN SCPTnPurchaseOrderDiscard_M ON SCPTnPurchaseOrderDiscard_M.PurchaseOrderId = SCPTnPurchaseOrder_D.PurchaseOrderId
    INNER JOIN SCPTnPurchaseOrderDiscard_D ON SCPTnPurchaseOrderDiscard_M.PurchaseOrderDiscardId = SCPTnPurchaseOrderDiscard_D.PurchaseOrderDiscardId 
	AND SCPTnPurchaseOrder_D.ItemCode=SCPTnPurchaseOrderDiscard_D.ItemCode
    LEFT OUTER JOIN SCPStReasonId ON SCPStReasonId.ReasonId = SCPTnPurchaseOrderDiscard_D.DiscardReasonId
    WHERE SCPTnPurchaseOrder_D.PurchaseOrderId=@PurchaseOrderId AND SCPTnPurchaseOrder_D.DiscardQty>0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscardPOMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>SCPStWraehouse
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDiscardPOMaster]
@PurchaseOrderId as VARCHAR(50)
AS
BEGIN
	SELECT PurchaseOrderId,PurchaseOrderDate,ItemTypeName FROM SCPTnPurchaseOrder_M
    INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId = SCPTnPurchaseOrder_M.WarehouseId
    INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = SCPStWraehouse.ItemTypeId WHERE PurchaseOrderId=@PurchaseOrderId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptDiscountSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPRptDiscountSummary] 
@From As varchar(12),
@To As varchar(12)
AS BEGIN

--SELECT Description,COUNT(DISTINCT ItemCode) Items,ISNULL(AVG(NULLIF(DISCOUNT,0)),0) DISCOUNT,SUM(NetAmount) Amount 
--FROM(
--	SELECT CASE WHEN DiscountValue=0 THEN 'No Discount' WHEN DiscountValue!=0 THEN 'Discount' END AS Description,
--	ItemCode,CASE WHEN DiscountValue=0 THEN 0 ELSE ((TotalAmount-AfterDiscountAmount)/TotalAmount)*100 END AS DISCOUNT,
--	SCPTnPharmacyIssuance_D.NetAmount FROM SCPTnPharmacyIssuance_D 
--	INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID = SCPTnPharmacyIssuance_M.TRNSCTN_ID AND IsApproved=1 AND SCPTnPharmacyIssuance_M.IsActive=1
--	WHERE CAST(SCPTnPharmacyIssuance_D.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@From,103) as date)
--	AND CAST(CONVERT(date,@To,103) as date)
--)TMPP GROUP BY Description


SELECT CASE WHEN DISCOUNT=0 THEN 'No Discount' WHEN DISCOUNT!=0 THEN 'Discount' END AS Description,
COUNT(ItemCode) AS Items,ISNULL(AVG(DISCOUNT_PER),0) AS DISCOUNT, SUM(ROUND(Amount,0)) AS Amount FROM 
(
	SELECT ItemCode,ISNULL(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN),0) AS DISCOUNT,
	SUM(TMP.NetAmount) Amount,(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN)/SUM(TMP.TotalAmount)*100)+AVG(TP_DISC)DISCOUNT_PER
	FROM(
		SELECT GRD.GoodReceiptNoteDetailId,GRD.ItemCode,TradePrice,GRD.ItemRate,
		((RecievedQty*PRIC.TradePrice-GRD.TotalAmount)/(RecievedQty*PRIC.TradePrice))*100 TP_DISC,
		BonusQty*ItemRate as BonusAmount,GRD.TotalAmount,(GRD.TotalAmount-GRD.AfterDiscountAmount) as DISCOUNT_GRN ,
		GRD.NetAmount FROM SCPTnGoodReceiptNote_D GRD
		INNER JOIN SCPTnGoodReceiptNote_M ON GRD.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId AND IsApproved=1 AND SCPTnGoodReceiptNote_M.IsActive=1
		INNER JOIN SCPTnPurchaseOrder_M ON SCPTnGoodReceiptNote_M.PurchaseOrderId = SCPTnPurchaseOrder_M.PurchaseOrderId
		LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = GRD.ItemCode AND SCPTnPurchaseOrder_M.PurchaseOrderDate BETWEEN FromDate AND ToDate AND PRIC.CostPrice = ItemRate
		WHERE CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date)  BETWEEN CAST(CONVERT(date,@From,103) as date)
		AND  CAST(CONVERT(date,@To,103) as date) AND SCPTnGoodReceiptNote_M.GRNType!=2
	   -- ORDER BY SCPTnPharmacyIssuance_D.ItemCode
	)TMP GROUP BY ItemCode
)TMPP GROUP BY (CASE WHEN DISCOUNT=0 THEN 'No Discount' WHEN DISCOUNT!=0 THEN 'Discount' END);




END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptFifoAuditReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROC [dbo].[Sp_SCPRptFifoAuditReport]
	@RACK_ID AS INT
	AS BEGIN
	
		SELECT SH_ITM.ItemCode,ITM.ItemName,BatchNo,
		(SELECT TOP 1 CONVERT(VARCHAR(10),GRND.CreatedDate, 105) FROM SCPTnGoodReceiptNote_D GRND WHERE GRND.ItemCode=SH_ITM.ItemCode 
		AND GRND.BatchNo=STK.BatchNo ORDER BY GRND.CreatedDate DESC) AS GRN_DATE,
		(SELECT TOP 1 GRND.GoodReceiptNoteId FROM SCPTnGoodReceiptNote_D GRND WHERE GRND.ItemCode=SH_ITM.ItemCode 
		AND GRND.BatchNo=STK.BatchNo ORDER BY GRND.CreatedDate DESC) AS GoodReceiptNo FROM SCPStRack RK
		INNER JOIN SCPStShelf SH ON SH.RackId = RK.RackId
		INNER JOIN SCPStItem_D_Shelf SH_ITM ON SH_ITM.ShelfId = SH.ShelfId
		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SH_ITM.ItemCode and ITM.IsActive=1
		INNER JOIN SCPTnStock_M STK ON SH_ITM.ItemCode = STK.ItemCode AND STK.WraehouseId=RK.WraehouseId
		WHERE RK.RackId=@RACK_ID AND STK.CurrentStock!=0
		GROUP BY SH_ITM.ItemCode,ITM.ItemName,BatchNo
		ORDER BY ITM.ItemName,GoodReceiptNo

	END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptIndentDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptIndentDetail]
@paramTransectionId VARCHAR(50)
AS
BEGIN
	SELECT IndentD.ItemCode AS ItemId,
			ItemM.ItemName AS ItemName,
			IndentD.RequestedQty AS RequiredQty,
			SCPStRate.CostPrice AS PurchasePrice
	FROM [dbo].[SCPTnIndent_D] AS IndentD 
	INNER JOIN SCPStRate ON SCPStRate.ItemCode = IndentD.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
	INNER JOIN [SCPStItem_M] AS ItemM ON ItemM.ItemCode = IndentD.ItemCode
	WHERE IndentD.IndentId =@paramTransectionId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptIndentMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptIndentMaster]
@parmTransectionId VARCHAR(50) 
AS
BEGIN

	SELECT IndentFormM.IndentId AS TransectionId,
		   Department.DepartmentName AS DepartmentName,
		   IndentFormM.CreatedDate AS IndentDate
	FROM [dbo].[SCPTnIndent_M] AS IndentFormM
	INNER JOIN [dbo].[SCPStDepartment] AS Department ON IndentFormM.DepartmentId = Department.DepartmentId
	WHERE IndentFormM.IndentId = @parmTransectionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptInventoryStockAndAdjustmentReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptInventoryStockAndAdjustmentReport] 
@FromDate as varchar(50),
@ToDate as varchar(50),
@WraehouseId AS INT
AS
BEGIN

SELECT ADJSTED_DATE,ItemCode,ItemName,CurrentStock,AMT,ItemBalance,PHYSICAL_AMT,CurrentStock-ItemBalance AS VARIANCE,
(CurrentStock-ItemBalance)*ItemRate AS ADJ_COST FROM
(
SELECT INVM.CreatedDate AS ADJSTED_DATE,CRP.ItemCode,ItemName,INV.BatchNo,ItemRate,
CurrentStock,ItemRate*CurrentStock AS AMT,ItemBalance,ItemBalance*ItemRate AS PHYSICAL_AMT FROM SCPStItem_M CRP
INNER JOIN SCPTnAdjustment_D INV ON INV.ItemCode = CRP.ItemCode
INNER JOIN SCPTnAdjustment_M INVM ON INV.AdjustmentId = INVM.AdjustmentId
WHERE INVM.IsActive=1 AND INVM.IsApprove=1 AND CRP.IsActive=1 AND
      CAST(INVM.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
      AND CAST(CONVERT(date,@ToDate,103) as date) AND WraehouseId=@WraehouseId
)TMPP
ORDER BY ADJSTED_DATE,ItemCode 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptInventoryValuation]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptInventoryValuation]
@WraehouseId AS INT
AS
BEGIN
	SELECT VendorChart,ItemCode,ItemName,MinLevel,MaxLevel,CAST(ROUND(CAST(MinLevel+MaxLevel AS FLOAT)/2,0) AS INT) AS MEAN_LVL,
	CostPrice,MinLevel*CostPrice AS MIN_VAL,MaxLevel*CostPrice AS MAX_VAL,
	(CAST(ROUND(CAST(MinLevel+MaxLevel AS FLOAT)/2,0) AS INT)*CostPrice) AS MEAN_VAL  FROM
    (
		SELECT VendorChart,ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CostPrice FROM
		(
		SELECT VendorChart,SCPStItem_M.ItemCode,ItemName,ISNULL(CASE WHEN ParLevelId=14 THEN NewLevel END,0) AS MinLevel,
		ISNULL(CASE WHEN ParLevelId=16 THEN NewLevel END,0) AS MaxLevel,CostPrice FROM SCPStItem_M
		INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = SCPStItem_M.ItemCode 
		INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
		INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
		INNER JOIN SCPStParLevelAssignment_M ON SCPStItem_M.ItemCode = SCPStParLevelAssignment_M.ItemCode
		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
		AND SCPStParLevelAssignment_M.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=SCPStItem_M.ItemCode AND WraehouseId=@WraehouseId)
		INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode
		AND SCPStRate.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
		WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=SCPStItem_M.ItemCode)
		INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
		WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
		)TMP#0 GROUP BY VendorChart,ItemCode,ItemName,CostPrice 
    )TMP#1 ORDER BY VendorChart,ItemName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptInvoiceSubmission]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptInvoiceSubmission] 
@dateee as varchar(50)
AS
BEGIN
	



SELECT * FROM (
SELECT *, DATEADD(DAY, DaysLimit, X.GRN_DATE) as DueDate,
DATEDIFF(WEEKDAY,CAST(CONVERT(date,@dateee,103) as date) ,DATEADD(DAY, DaysLimit, X.GRN_DATE)) 
AS DAYYY  FROM (
select SupplierLongName, PurchaseOrderId, GoodReceiptNoteId, InvoiceNo,
CASE WHEN SCPTnGoodReceiptNote_M.EditedDate IS NULL THEN (SELECT SCPTnGoodReceiptNote_M.GoodReceiptNoteDate)
ELSE (SELECT SCPTnGoodReceiptNote_M.EditedDate)
END AS GRN_DATE 
 ,sup.DaysLimit
from SCPTnGoodReceiptNote_M
inner join SCPStSupplier sup on sup.SupplierId = SCPTnGoodReceiptNote_M.SupplierId
where  InvoiceNo IS NOT NULL
)X
--where cast(GRN_DATE as date)= CAST(CONVERT(date,'22-10-2018',103) as date) 
)Y WHERE DAYYY <=3 AND  DAYYY >= 0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptIssuance_Summary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptIssuanceSummary]
@FromDate VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;
   
SELECT Demand_Id  ,Demand_Date,COUNT(Iss_Item) as Iss_Item, COUNT(Dem_Item) AS Dem_Item  , 
SUM((DemandQty* (case when RATE is null then Dmnd_Rate else RATE end))) AS dEMAND_AMOUNT, Issued_Id, Issued_Date,
SUM((IssueQty*rate)) AS Issued_Amount FROM(
select *,(select CostPrice from SCPStRate where ItemCode=Dem_Item and GETDATE() between FromDate and ToDate) as Dmnd_Rate from
(
SELECT D_D.DemandId as Demand_Id,CAST(CAST( D_D.CreatedDate AS date)AS datetime) as Demand_Date,
 CASE WHEN GRN.ItemRate IS NULL THEN PRIC.CostPrice ELSE GRN.ItemRate END AS RATE, 
D_D.DemandQty, STK.StockQuantity as IssueQty,CAST(CAST( I_D.CreatedDate AS date) AS datetime) AS Issued_Date, I_D.ItemCode AS Iss_Item,
D_D.ItemCode AS Dem_Item,I_D.PharmacyIssuanceId as Issued_Id FROM  SCPTnDemand_D D_D
 LEFT OUTER JOIN  SCPTnPharmacyIssuance_D I_D ON I_D.DemandId = D_D.DemandId AND I_D.ItemCode = D_D.ItemCode
 LEFT OUTER JOIN SCPTnStock_D STK ON STK.ItemCode = I_D.ItemCode  AND STK.TransactionDocumentId =I_D.PharmacyIssuanceId AND WraehouseId =10
 LEFT OUTER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode = D_D.ItemCode AND STK.BatchNo = STOCK.BatchNo AND STOCK.WraehouseId =10
 LEFT OUTER  JOIN SCPTnGoodReceiptNote_D GRN ON GRN.BatchNo = STK.BatchNo AND GRN.ItemCode = STK.ItemCode 
 AND GRN.GoodReceiptNoteId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteId FROM SCPTnGoodReceiptNote_D 
 WHERE SCPTnGoodReceiptNote_D.ItemCode = STK.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = STOCK.BatchNo ORDER BY CreatedDate DESC)
 LEFT OUTER JOIN SCPStRate PRIC on PRIC.ItemCode = D_D.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
WHERE CONVERT(date,STOCK.CreatedDate) between FromDate and ToDate and SCPStRate.ItemCode= D_D.ItemCode )
WHERE cast(D_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
     AND CAST(CONVERT(date,@ToDate,103) as date)
)tmpp
  )TMP
  group by Demand_Id, Issued_Id, Issued_Date, Demand_Date
   order by Issued_Id,Demand_Id
--SELECT Demand_Id  ,Demand_Date,		
--COUNT(Iss_Item) as Iss_Item, COUNT(Dem_Item) AS Dem_Item  , SUM((DemandQty* RATE)) AS dEMAND_AMOUNT, Issued_Id, Issued_Date,
--SUM((IssueQty*rate)) AS Issued_Amount

-- FROM(
--SELECT I_D.DemandId as Demand_Id,CAST(CAST( D_D.CreatedDate AS date)AS datetime) as Demand_Date, PRIC.CostPrice AS RATE, 
--I_D.DemandQty, I_D.IssueQty,CAST(CAST( I_D.CreatedDate AS date) AS datetime) AS Issued_Date, I_D.ItemCode AS Iss_Item, D_D.ItemCode AS Dem_Item,
--I_D.PARENT_TRNSCTN_ID as Issued_Id FROM  SCPTnDemand_D D_D
-- INNER JOIN  SCPTnPharmacyIssuance_D I_D
--  ON I_D.DemandId = D_D.PARENT_TRNSCTN_ID AND I_D.ItemCode = D_D.ItemCode
-- inner join SCPStRate PRIC on PRIC.ItemCode = D_D.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
--WHERE CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= D_D.ItemCode )
--WHERE cast(I_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
--     AND CAST(CONVERT(date,@ToDate,103) as date)
--  )TMP
--  group by Demand_Id, Issued_Id, Issued_Date, Demand_Date
--  order by Issued_Date
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptIssuanceDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptIssuanceDetail]
	
	@FromDate VARCHAR(50),
	@ToDate VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;
	
		SELECT *, (ISSUED_QTY* ITM_RATE) AS ITM_AMOUNT FROM (
			SELECT PHM.PharmacyIssuanceId, PHM.ItemCode, ItemName, 
			STK.BatchNo AS BatchNo, GRN.ExpiryDate,	stk.StockQuantity AS ISSUED_QTY, 
			CASE WHEN GRN.ItemRate IS NULL THEN PRIC.CostPrice ELSE GRN.ItemRate END AS ITM_RATE
			FROM SCPTnPharmacyIssuance_D PHM 
			INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PHM.ItemCode 
			INNER JOIN SCPTnStock_D STK ON STK.ItemCode = PHM.ItemCode  AND STK.TransactionDocumentId =PHM.PharmacyIssuanceId AND WraehouseId =10
			INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode = ITM.ItemCode AND STK.BatchNo = STOCK.BatchNo AND STOCK.WraehouseId =10
			LEFT OUTER JOIN SCPTnGoodReceiptNote_D GRN ON GRN.BatchNo = STK.BatchNo AND GRN.ItemCode = STK.ItemCode
			AND GRN.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
			WHERE SCPTnGoodReceiptNote_D.ItemCode = STK.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = STOCK.BatchNo ORDER BY CreatedDate DESC)
   			LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = ITM.ItemCode AND PRIC.FromDate <= STOCK.CreatedDate and PRIC.ToDate >= STOCK.CreatedDate
			WHERE cast(PHM.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
			 AND CAST(CONVERT(date,@ToDate,103) as date)
			)X ORDER BY PharmacyIssuanceId,ItemName

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemRefundToStore]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptItemRefundToStore] 
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

SELECT *, (RATE *X.ReturnQty) AS Amount FROM (
SELEct MS.ReturnToStoreId, DT.ItemCode, ITEM.ItemName, MS.ReturnToStoreDate, 
CONVERT(VARCHAR(50),ClassName) as ClassName, DOS.DosageName, ST.StrengthIdName, DT.BatchNo,
 CASE WHEN GRN.ItemRate IS NULL THEN PRIC.CostPrice ELSE GRN.ItemRate END AS RATE, 
 DT.ReturnQty, RSN.ReasonId  from SCPTnReturnToStore_M  MS 
INNER JOIN SCPTnReturnToStore_D DT ON MS.ReturnToStoreId = DT.ReturnToStoreId
INNER JOIN SCPStItem_M ITEM ON ITEM.ItemCode = DT.ItemCode
INNER JOIN SCPStClassification CLS ON CLS.ClassId = ITEM.ClassId
INNER JOIN SCPStDosage DOS ON DOS.DosageId = ITEM.DosageFormId
LEFT OUTER JOIN SCPStStrengthId ST ON ST.StrengthIdId = ITEM.StrengthId
INNER JOIN SCPStReasonId RSN ON RSN.ReasonId = DT.ReturnReasonIdId
INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode =DT.ItemCode AND DT.BatchNo = STOCK.BatchNo AND STOCK.WraehouseId =10
LEFT OUTER  JOIN SCPTnGoodReceiptNote_D GRN ON GRN.BatchNo = DT.BatchNo AND GRN.ItemCode = DT.ItemCode 
AND GRN.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
WHERE SCPTnGoodReceiptNote_D.ItemCode = DT.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = DT.BatchNo ORDER BY CreatedDate DESC)
LEFT OUTER JOIN SCPStRate PRIC on PRIC.ItemCode = DT.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
WHERE CONVERT(date,STOCK.CreatedDate) between FromDate and ToDate and SCPStRate.ItemCode= DT.ItemCode)
WHERE cast(MS.ReturnToStoreDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND
CAST(CONVERT(date,@ToDate,103) as date) and MS.IsApprove=1
							)X
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemReturntoSupplierD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptItemReturntoSupplier_D]
@paramTransectionId AS INT
AS
BEGIN

		SELECT RSD.ItemCode AS ItemCode,
			   RSD.BatchNo AS BatchNo,
			   ItemM.ItemName AS ItemName,
			   RSD.ItemRate AS PurchasePrice,
			   SUM(RSD.NetAmount) AS ItemCount,
			   SUM(RSD.ReturnQty) AS Amount

			   FROM [dbo].[SCPTnReturnToSupplier_D] AS RSD
	   INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON RSD.ItemCode = ItemM.ItemCode
	   WHERE RSD.ReturntoSupplierId = @paramTransectionId
	   GROUP BY RSD.ItemCode ,
				RSD.BatchNo,
				ItemM.ItemName,
				RSD.ItemRate
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemReturntoSupplierM]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptItemReturntoSupplier_M]
@paramTransectionId AS INT
AS
BEGIN
		SELECT RSM.ReturnToSupplierId AS TransectionId,
			   RSM.DatePassCode AS GatePassCode,
			   WraehouseNames.WraehouseName AS WraehouseNameName,
			   Supplier.SupplierLongName AS SupplieName
			   FROM [dbo].[SCPTnReturnToSupplier_M] AS RSM
		INNER JOIN [dbo].[SCPStSupplier] AS Supplier ON Supplier.SupplierId = RSM.SupplierId
		INNER JOIN [dbo].[SCPStWraehouse] AS WraehouseNames ON WraehouseNames.WraehouseId = RSM.WraehouseId
		WHERE RSM.ReturnToSupplierId = @paramTransectionId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptItemWiseRate]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptItemWiseRate]

@SupId as int,
@ManId as int,
@ItmId as int
AS
BEGIN
	
	SET NOCOUNT ON;
if(@SupId = 0 )
begin
 SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice AS TP, Discount, CostPrice AS PP , SalePrice AS MRP  
from  SCPStItem_M INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= SCPStItem_M.ItemCode)
 WHERE ManufacturerId = @ManId and SCPStItem_M.ItemTypeId  = @ItmId
 end
 else
 begin
    SELECT SCPStItem_D_Supplier.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice AS TP, Discount, CostPrice AS PP , SalePrice AS MRP  FROM SCPStItem_D_Supplier
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPStItem_D_Supplier.ItemCode
INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_D_Supplier.ItemCode AND ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= SCPStItem_M.ItemCode)
 WHERE SupplierId = @SupId and SCPStItem_M.ItemTypeId  = @ItmId
 end
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptLocalPurchase]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptLocalPurchase]

@FromDate VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN
	SELECT CAST(GoodReceiptNoteDate AS DATE) LP_DATE,SCPTnGoodReceiptNote_D.ItemCode,ItemName AS BRAND,GenericName,StrengthIdName,DosageName,SCPTnGoodReceiptNote_D.RecievedQty,
CASE WHEN SCPStItem_M.FormularyId IS NULL THEN '' ELSE FormularyName END AS FormularyName FROM SCPTnGoodReceiptNote_M
INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
INNER JOIN SCPStStrengthId ON SCPStStrengthId.StrengthIdId = SCPStItem_M.StrengthId
INNER JOIN SCPStGeneric ON SCPStGeneric.GenericId = SCPStItem_M.GenericId
LEFT OUTER JOIN SCPStFormulary ON SCPStFormulary.FormularyId = SCPStItem_M.FormularyId
INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
 WHERE 
  CAST(GoodReceiptNoteDate as date) BETWEEN 
		   CAST(CONVERT(date, @FromDate,103) as date) AND
		CAST(CONVERT(date,@ToDate,103) as date) AND
 GRNType=2
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMedicalNeedItemReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPRptMedicalNeedItemReport]
@WraehouseName INT,
@FromDate as varchar(50),
@ToDate as varchar(50)

AS BEGIN

declare @DAYS INT = (SELECT TOP 1 ParLevelConsumptionDays FROM SCPStAutoParLevel_M WHERE WraehouseId=@WraehouseName)
declare @MIN_DAYS AS MONEY=(SELECT ParLevelDays FROM SCPStAutoParLevel_M WHERE WraehouseId=@WraehouseName AND ParLevelId=14)
declare @MAX_DAYS AS MONEY=(SELECT ParLevelDays FROM SCPStAutoParLevel_M WHERE WraehouseId=@WraehouseName AND ParLevelId=16)
declare @LAST_CYCLE_DAYS AS MONEY=(SELECT TOP 1 DATEDIFF(D,CreatedDate,GETDATE()) FROM SCPTnAutoParLevel 
                                   WHERE WraehouseId=@WraehouseName ORDER BY CreatedDate DESC)
declare @DAYS_DIFF AS INT = (SELECT DATEDIFF(D,CAST(CONVERT(date,@FromDate,103) as date),CAST(CONVERT(date,@ToDate,103) as date)))

IF(@WraehouseName= 3)
	BEGIN

	SELECT TMPPPP.ItemCode,ItemName,CostPrice,SUM(CurrentStock) CurrentStock,
	CASE WHEN MIN_PRDCTD_PAR_LVL<= 0 THEN 1 ELSE MIN_PRDCTD_PAR_LVL END AS MIN_PRDCTD_PAR_LVL,
	CASE WHEN MAX_PRDCTD_PAR_LVL<= 0 THEN 1 ELSE MAX_PRDCTD_PAR_LVL END AS MAX_PRDCTD_PAR_LVL,
	CASE WHEN MEAN_PRDCTD_PAR_LVL<= 0 THEN 1 ELSE MEAN_PRDCTD_PAR_LVL END AS MEAN_PRDCTD_PAR_LVL,MinLevel,MaxLevel,MEAN_LVL, 
	CASE WHEN NEW_MIN_PAR_LVL<= 0 THEN 1 ELSE NEW_MIN_PAR_LVL END AS NEW_MIN_PAR_LVL,
	CASE WHEN NEW_MAX_PAR_LVL<= 0 THEN 1 ELSE NEW_MAX_PAR_LVL END AS NEW_MAX_PAR_LVL,
	CASE WHEN NEW_MEAN_PAR_LVL<= 0 THEN 1 ELSE NEW_MEAN_PAR_LVL END AS NEW_MEAN_PAR_LVL,SALES,Amount
	FROM
	(
		SELECT ItemCode,ItemName,CostPrice,CAST(MIN_PRDCTD_PAR_LVL AS INT) AS MIN_PRDCTD_PAR_LVL,
		CAST(MAX_PRDCTD_PAR_LVL AS bigint) AS MAX_PRDCTD_PAR_LVL,
		CAST(ROUND((MIN_PRDCTD_PAR_LVL+MAX_PRDCTD_PAR_LVL)/2,0) AS INT) AS MEAN_PRDCTD_PAR_LVL,
		CAST(NEW_MIN_PAR_LVL AS INT) AS NEW_MIN_PAR_LVL,CAST(NEW_MAX_PAR_LVL AS bigint) AS NEW_MAX_PAR_LVL,
		CAST(ROUND((NEW_MIN_PAR_LVL+NEW_MAX_PAR_LVL)/2,0) AS INT) AS NEW_MEAN_PAR_LVL,
		MinLevel,MaxLevel,CAST(ROUND((MinLevel+MaxLevel)/2,0) AS INT) AS MEAN_LVL,SALES,Amount FROM
		(
			SELECT TMPP.ItemCode,ItemName,ISNULL(CostPrice,0) AS CostPrice,CAST(ROUND(DAILY_AVERAGE*@MIN_DAYS,0) AS INT) AS MIN_PRDCTD_PAR_LVL,
			CAST(ROUND(DAILY_AVERAGE*@MAX_DAYS,0) AS INT) AS MAX_PRDCTD_PAR_LVL,MinLevel,MaxLevel,CAST(ROUND(NEW_DAILY_AVERAGE*@MIN_DAYS,0) AS INT) AS NEW_MIN_PAR_LVL,
			CAST(ROUND(NEW_DAILY_AVERAGE*@MAX_DAYS,0) AS INT) AS NEW_MAX_PAR_LVL,SALES,Amount FROM	
			(
			    SELECT TMP2.ItemCode,ItemName,MinLevel,MaxLevel,DAILY_AVERAGE,ISNULL(SUM(CAST(Quantity AS FLOAT)),0) AS SALES,ISNULL(SUM(ROUND(Quantity*ItemRate,0)),0) AS Amount,
			    ISNULL(SUM(CAST(Quantity AS FLOAT)),0)/CAST(@DAYS_DIFF AS FLOAT) AS NEW_DAILY_AVERAGE FROM
				(
					SELECT ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,
					(CAST(ISNULL(SOLD_QTY,0) AS FLOAT)/CAST(@DAYS AS FLOAT)) AS DAILY_AVERAGE FROM
					(
						SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(CAST(Quantity AS bigint)),0) AS SOLD_QTY,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
						LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode AND CAST(SCPTnSale_D.CreatedDate AS DATE) 
						BETWEEN DATEADD(DAY, -(@DAYS+@LAST_CYCLE_DAYS), GETDATE()) AND DATEADD(DAY, -@LAST_CYCLE_DAYS, GETDATE())
						INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseName
						INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
						AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
						AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
						AND CC.WraehouseId=@WraehouseName AND CC.IsActive=1)
							WHERE SCPStItem_M.IsActive=1 AND DATEDIFF(DAY,SCPStItem_M.CreatedDate,GETDATE())>=(@DAYS+@LAST_CYCLE_DAYS)
						AND ISNULL(SCPStItem_M.MedicalNeedItem,0)=1
						GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
					)TMP GROUP BY ItemCode,ItemName,SOLD_QTY
				)TMP2
				LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = TMP2.ItemCode AND CAST(SCPTnSale_D.CreatedDate AS DATE) 
			    BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
				GROUP BY TMP2.ItemCode,ItemName,MinLevel,MaxLevel,DAILY_AVERAGE
			)TMPP 
			LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = TMPP.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	        FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=TMPP.ItemCode)
			GROUP BY TMPP.ItemCode,ItemName,CostPrice,MinLevel,MaxLevel,DAILY_AVERAGE,NEW_DAILY_AVERAGE,SALES,Amount
		)TMPPPP
	)TMPPPP 
	INNER JOIN SCPTnStock_M ON TMPPPP.ItemCode = SCPTnStock_M.ItemCode AND WraehouseId=@WraehouseName
	GROUP BY TMPPPP.ItemCode,ItemName,CostPrice,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,MEAN_PRDCTD_PAR_LVL,
	MinLevel,MaxLevel,MEAN_LVL,NEW_MIN_PAR_LVL,NEW_MAX_PAR_LVL,NEW_MEAN_PAR_LVL,SALES,Amount
	ORDER BY ItemName

	END

ELSE

	BEGIN

	SELECT TMPPPP.ItemCode,ItemName,CostPrice,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,SUM(CurrentStock) CurrentStock,
	CAST(ROUND((MIN_PRDCTD_PAR_LVL+MAX_PRDCTD_PAR_LVL)/2,0) AS INT) AS MEAN_PRDCTD_PAR_LVL,MinLevel,MaxLevel,
	CAST(ROUND((MinLevel+MaxLevel)/2,0) AS INT) AS MEAN_LVL,NEW_MIN_PAR_LVL,NEW_MAX_PAR_LVL,
	CAST(ROUND((NEW_MIN_PAR_LVL+NEW_MAX_PAR_LVL)/2,0) AS INT) AS NEW_MEAN_PAR_LVL,SALES,Amount FROM
	(
		SELECT ItemCode,ItemName,CostPrice,MinLevel,MaxLevel,SALES,Amount,
		CAST(CASE WHEN MIN_PRDCTD_PAR_LVL > 0 AND MIN_PRDCTD_PAR_LVL< 1 THEN 1 ELSE MIN_PRDCTD_PAR_LVL END AS INT) AS MIN_PRDCTD_PAR_LVL,
		CAST(CASE WHEN MAX_PRDCTD_PAR_LVL > 0 AND MAX_PRDCTD_PAR_LVL< 2 THEN 2 ELSE MAX_PRDCTD_PAR_LVL END AS bigint) AS MAX_PRDCTD_PAR_LVL,
		CAST(CASE WHEN NEW_MIN_PAR_LVL > 0 AND NEW_MIN_PAR_LVL< 1 THEN 1 ELSE NEW_MIN_PAR_LVL END AS INT) AS NEW_MIN_PAR_LVL,
		CAST(CASE WHEN NEW_MAX_PAR_LVL > 0 AND NEW_MAX_PAR_LVL< 2 THEN 2 ELSE NEW_MAX_PAR_LVL END AS bigint) AS NEW_MAX_PAR_LVL
		FROM
		(
			SELECT TMPP.ItemCode AS ItemCode,ItemName,ISNULL(CostPrice,0) AS CostPrice,SALES,Amount,MinLevel,MaxLevel,
			CAST(ROUND(DAILY_AVERAGE*@MIN_DAYS*TotalSupplyDays,0) AS INT) AS MIN_PRDCTD_PAR_LVL,
			CAST(ROUND(DAILY_AVERAGE*@MAX_DAYS*TotalSupplyDays,0) AS INT) AS MAX_PRDCTD_PAR_LVL,
			CAST(ROUND(NEW_DAILY_AVERAGE*@MIN_DAYS*TotalSupplyDays,0) AS INT) AS NEW_MIN_PAR_LVL,
			CAST(ROUND(NEW_DAILY_AVERAGE*@MAX_DAYS*TotalSupplyDays,0) AS INT) AS NEW_MAX_PAR_LVL FROM	
			(
				SELECT TMP2.ItemCode,ItemName,MinLevel,MaxLevel,DAILY_AVERAGE,ISNULL(SUM(CAST(Quantity AS FLOAT)),0) AS SALES,ISNULL(SUM(ROUND(Quantity*ItemRate,0)),0) AS Amount,
				ISNULL(SUM(CAST(Quantity AS FLOAT)),0)/CAST(@DAYS_DIFF AS FLOAT) AS NEW_DAILY_AVERAGE 
				FROM(
					SELECT ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,
					CAST(ISNULL(SOLD_QTY,0) AS FLOAT)/CAST(@DAYS AS FLOAT) AS DAILY_AVERAGE FROM
					(
						SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(CAST(Quantity AS bigint)),0) AS SOLD_QTY,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
						LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode AND CAST(SCPTnSale_D.CreatedDate AS DATE) 
						BETWEEN DATEADD(DAY, -(@DAYS+@LAST_CYCLE_DAYS), GETDATE()) AND DATEADD(DAY, -@LAST_CYCLE_DAYS, GETDATE())
						INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseName
						INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
						AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
						AND CC.WraehouseId=@WraehouseName AND CC.IsActive=1)
						WHERE SCPStItem_M.IsActive=1 AND DATEDIFF(DAY,SCPStItem_M.CreatedDate,GETDATE())>=(@DAYS+@LAST_CYCLE_DAYS)
						AND ISNULL(SCPStItem_M.MedicalNeedItem,0)=1
						GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel,ItemPackingQuantity
					)TMP GROUP BY ItemCode,ItemName,SOLD_QTY
				)TMP2
				LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = TMP2.ItemCode AND CAST(SCPTnSale_D.CreatedDate AS DATE) 
				BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
				GROUP BY TMP2.ItemCode,ItemName,MinLevel,MaxLevel,DAILY_AVERAGE
			)TMPP 
			INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = TMPP.ItemCode 
			INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
			INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
			LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = TMPP.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		    FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=TMPP.ItemCode)
			GROUP BY VendorChart,TMPP.ItemCode,ItemName,CostPrice,MinLevel,MaxLevel,TotalSupplyDays,DAILY_AVERAGE,NEW_DAILY_AVERAGE,SALES,Amount
		)TMPPPP 
	)TMPPPP 
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = TMPPPP.ItemCode AND WraehouseId=@WraehouseName 
	GROUP BY TMPPPP.ItemCode,ItemName,CostPrice,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,MinLevel,MaxLevel,
	NEW_MIN_PAR_LVL,NEW_MAX_PAR_LVL,SALES,Amount
	ORDER BY ItemName

	END

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMnthlyPurchaseSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptMnthlyPurchaseSummary]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

	SELECT ItemTypeName,ISNULL(TTL_UN_AUTH,0) AS TTL_UN_AUTH,ISNULL(TTL_AUTH,0) AS TTL_AUTH,ISNULL(TTL_PUR,0) AS TTL_PUR,
    ISNULL(TTL_UN_AUTH,0)*100/ISNULL(TTL_PUR,0) as KPI FROM 
	(
	SELECT ItemTypeName,SUM(PCM.NetAmount) AS TTL_PUR,(SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M 
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (22,23) 
	AND SCPTnGoodReceiptNote_M.WraehouseId=SCPStWraehouse.WraehouseId AND CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE)) AS TTL_UN_AUTH,
	(SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (20,21) 
	AND SCPTnGoodReceiptNote_M.WraehouseId=SCPStWraehouse.WraehouseId AND CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE))  AS TTL_AUTH FROM SCPTnGoodReceiptNote_M PCM
	INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId = PCM.WraehouseId 
	INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = SCPStWraehouse.ItemTypeId
	WHERE SCPStItemType.ItemTypeId=2 AND IsApproved=1 AND SCPStWraehouse.IsAllow=1 AND CAST(PCM.GoodReceiptNoteDate AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE) 
	GROUP BY SCPStWraehouse.WraehouseId,ItemTypeName 
	UNION ALL
	SELECT ClassName,SUM(PRC.NetAmount) AS TTL_PUR,(SELECT SUM(SCPTnGoodReceiptNote_D.NetAmount) FROM SCPStItem_M
	INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPStItem_M.ClassId = CPM.ClassId 
	INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.GoodReceiptNoteId = SCPTnGoodReceiptNote_D.GoodReceiptNoteId
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (22,23) 
	AND CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) 
	AND CAST(CONVERT(DATE,SCPTnGoodReceiptNote_M.GoodReceiptNoteDate,103) AS DATE)) AS TTL_UN_AUTH,(SELECT SUM(SCPTnGoodReceiptNote_D.NetAmount) FROM SCPStItem_M
	INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode AND SCPStItem_M.ClassId = CPM.ClassId 
	INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.GoodReceiptNoteId = SCPTnGoodReceiptNote_D.GoodReceiptNoteId
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId WHERE SupplierCategoryId IN (20,21) 
	AND CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) 
	AND CAST(CONVERT(DATE,@ToDate,103) AS DATE)) AS TTL_AUTH FROM SCPStItem_M CPM
	INNER JOIN SCPStClassification ON SCPStClassification.ClassId = CPM.ClassId
	INNER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CPM.ItemCode
	INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCM.GoodReceiptNoteId = PRC.GoodReceiptNoteId
	WHERE CPM.ItemTypeId=1 AND IsApproved=1 AND CAST(PRCM.GoodReceiptNoteDate AS date) 
	BETWEEN CAST(CONVERT(DATE,@FromDate,103) AS DATE) AND CAST(CONVERT(DATE,@ToDate,103) AS DATE) GROUP BY CPM.ClassId,ClassName 
	)TMP

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptModified_PR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptModifiedPR]
@ItemTypeId INT,
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
--SELECT 
--       PRM.TRANSCTN_ID AS PR_Number,
--	   PRM.CreatedDate AS CreatedOn,
--	   COUNT(CASE WHEN PurchaseRequisitionId != '0' AND POD.RequestedQty != POD.OrderQty  THEN POD.TRNSCTN_ID END) AS ModifiedItem
--FROM [dbo].[SCPTnPurchaseRequisition_M] AS PRM
--INNER JOIN [dbo].[SCPTnPurchaseRequisition_D] AS PRD ON PRD.PARENT_TRANS_ID = PRM.TRANSCTN_ID
--INNER JOIN [dbo].[SCPTnPurchaseOrder_D] AS POD ON POD.PurchaseRequisitionId = PRD.PARENT_TRANS_ID
--WHERE PRM.ProcurementId = @paramItemTypeId AND
--      CAST(PRM.CreatedDate as date) BETWEEN 
--	  CAST(CONVERT(date, @paramFromDate,103) as date) AND
--	  CAST(CONVERT(date,@paramToDate,103) as date) 
--GROUP BY 
--		 PRM.TRANSCTN_ID,
--		 PRM.CreatedDate


		 SELECT PurchaseOrderId AS PR_Number, SCPTnPurchaseOrder_D.CreatedDate  AS CreatedOn, COUNT(ItemCode)  AS ModifiedItem
	FROM SCPTnPurchaseOrder_D 
	INNER JOIN SCPTnPurchaseOrder_M MSTR ON MSTR.PurchaseOrderId = SCPTnPurchaseOrder_D.PurchaseOrderId
	INNER JOIN SCPStWraehouse WHR ON WHR.WraehouseId = MSTR.WarehouseId
	WHERE RequestedQty != OrderQty AND PurchaseRequisitionId != '0' AND CAST(SCPTnPurchaseOrder_D.CreatedDate as date) 
	BETWEEN 
	  CAST(CONVERT(date, @paramFromDate,103) as date) AND
	  CAST(CONVERT(date,@paramToDate,103) as date)  AND ItemTypeId = @ItemTypeId
 GROUP BY  PurchaseOrderId, SCPTnPurchaseOrder_D.CreatedDate
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMonthly_CO_Sale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptMonthlyCareOfSale]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
	WITH CTE_MonthlyCOSale(SaleInvoiceNo,
						   CreatedOn,
						   SCPTnInPatientType,
						   IP,
						   ItemName,
						   DoseName,
						   CareOf,
						   TotalQty,
						   TotalAmount,
						   TotalRefundQty)
AS
(
	SELECT SaleM.SaleId AS SaleInvoiceNo,
		   SaleM.CreatedDate AS CreatedOn,
		   Pt.PatientCategoryName AS SCPTnInPatientType,
		   SaleM.PatientIp AS IP,
		   ItemM.ItemName AS ItemName,
		   Dose.DosageName AS DoseName,
		   (CASE WHEN SaleM.CareOffCode = 1 THEN 'Employee' WHEN SaleM.CareOffCode=2 THEN 'Consultant' WHEN SaleM.CareOffCode = 3 THEN 'Partner' END) AS CareOf,
		   SUM(SaleD.Quantity) AS TotalQty,
		   SUM(SaleD.Amount) AS TotalAmount,
		   SUM(RefundD.ReturnQty) AS TotalRefundQty
		  -- SUM(RefundD.ReturnAmount) AS TotalRefundAmount
		   --SUM(ItemPackingQuantity) OVER (Partition BY SaleM.SaleId) AS QTY
		FROM [SCPStPatientCategory] AS PT
		INNER JOIN [dbo].[SCPTnSale_M] AS SaleM  ON PT.PatientCategoryId  = PT.PatientCategoryId
		INNER JOIN [dbo].[SCPTnSale_D] AS SaleD ON SaleD.SaleId = SaleM.SaleId
		INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON ItemM.ItemCode = SaleD.ItemCode
		INNER JOIN [dbo].[SCPStDosage] AS Dose ON Dose.DosageId = ItemM.DosageFormId
		LEFT JOIN [dbo].[SCPTnSaleRefund_M] AS RefundM On SaleM.SaleId = RefundM.SaleId
		LEFT JOIN [dbo].[SCPTnSaleRefund_D] AS RefundD ON RefundM.SaleRefundId = RefundD.SaleRefundId
		
		WHERE SaleM.CareOffCode IN (1, 2, 3) 
		AND 
			  CAST(SaleM.CreatedDate as date) BETWEEN 
			  CAST(CONVERT(date,@paramFromDate,103) as date) AND 
			  CAST(CONVERT(date,@paramToDate,103) as date)
		GROUP BY CASE WHEN SaleM.CareOffCode = 1 THEN 'Employee' WHEN SaleM.CareOffCode=2 THEN 'Consultant' WHEN SaleM.CareOffCode = 3 THEN 'Partner' END,
				 Pt.PatientCategoryName,
				 SaleM.CreatedDate,
				 ItemM.ItemName,
				 SaleM.SaleId,
				 SaleM.PatientIp,
				 Dose.DosageName
)
SELECT SaleInvoiceNo,
	   CreatedOn,
	   SCPTnInPatientType,
	   IP,
	   ItemName,
	   DoseName,
	   CareOf,
	   ISNULL(TotalQty,0) AS TotalQty,
	   ISNULL(TotalAmount,0)AS TotalAmount,
	   ISNULL(TotalRefundQty,0) AS TotalRefund,
	   ISNULL(TotalAmount/TotalRefundQty,0) AS TotalRefundAmount
FROM CTE_MonthlyCOSale
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMonthlyInventoryDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailPOS_M]
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin
SET NOCOUNT ON
DECLARE @userData TABLE(
    
    [Date] datetime
);
DECLARE @FinalData TABLE(
    
    Date varchar(50),
	OpeningClose decimal(18,2),
	sale decimal(18,2),
	sale_refund decimal(18,2),
	issued_amt decimal(18,2),
	refund_pos_amt decimal(18,2),	
	discard decimal(18,2),
	adj decimal(18,2),
	Closing decimal(18,2)
);

insert into @userData([Date])
select CONVERT(date,inv1.CreatedDate ,103) as Date 
	from SCPTnStock_D inv1  
	where cast(inv1.CreatedDate as date) 
	between cast(CONVERT(date,@FirstDate  ,103) as date) and cast(CONVERT(date,@LimitDate  ,103) as date)
	group by CONVERT(date,inv1.CreatedDate ,103)

DECLARE @Date datetime;
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(Date,OpeningClose,sale,sale_refund,issued_amt,refund_pos_amt,discard,adj,Closing)
execute Sp_SCPMonthlyInventoryDetailDayWisePOS @WraehouseName,@Date
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  


select *,cast(Date as datetime) as Data_Dt from @FinalData order by cast(Date as datetime) 

end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptMonthlySaleSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptMonthlySaleSummary]  
 -- Add the parameters for the stored procedure here
	@PatientCategoryId int = 0,
	@PatientTypeId int = 0,
	@FromDate AS VARCHAR(50),
    @ToDate AS VARCHAR(50)
AS
BEGIN
	
	--declare @month nvarchar(50), @year nvarchar(50);
 
	--set @month = datepart(month , cast(CONVERT(datetime,@date,103) as datetime)); 
	--set @year = datepart(year , cast(CONVERT(datetime,@date,103) as datetime));
 
	if @PatientCategoryId = 0 and @PatientTypeId = 0
	begin
 
	SELECT Month_Year,PatientCategoryName,PatientSubCategoryName,PatientTypeName,SUM(Prescription) AS No_of_SCPTnInPatient,
	SUM(SaleAmount) Total_Sale,SUM(RefundAmount) AS Total_Refunds,SUM(SaleAmount)-SUM(RefundAmount) AS Net_sale FROM
	(
	SELECT MONTH(PHM.SaleRefundDate) AS MonthNumbr,Format(PHM.SaleRefundDate,'MMM-yyyy') Month_Year,
	PatientCategoryName AS PatientCategoryName,PatientSubCategoryName,PatientTypeName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	INNER JOIN SCPTnSale_M PMM ON PMM.SaleId = PHM.SaleId  AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientType PT_T ON PMM.PatientTypeId = PT_T.PatientTypeId
	inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and pmm.PatientSubCategoryId = pt_sb.PatientSubCategoryId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1 
	GROUP BY  MONTH(PHM.SaleRefundDate),Format(PHM.SaleRefundDate,'MMM-yyyy'),PatientCategoryName,PatientSubCategoryName,PatientTypeName
	UNION ALL
	SELECT MONTH(PHM.SaleRefundDate) AS MonthNumbr,Format(PHM.SaleRefundDate,'MMM-yyyy') Month_Year,
	PatientCategoryName AS PatientCategoryName,(CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 
	THEN 'OT' ELSE 'Per' END) AS PatientSubCategoryName,PatientTypeName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientType PT_T ON PMM.PatientTypeId = PT_T.PatientTypeId
	--inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and pmm.PatientSubCategoryId = pt_sb.PatientSubCategoryId
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY MONTH(PHM.SaleRefundDate),Format(PHM.SaleRefundDate,'MMM-yyyy'),PatientCategoryName,
	(CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 THEN 'OT' ELSE 'Per' END),PatientTypeName
	UNION ALL
	SELECT MONTH(PRE_DATE) AS MonthNumbr,Format(PRE_DATE,'MMM-yyyy') Month_Year,
	PT_CT.PatientCategoryName  AS PatientCategoryName,pt_sb.PatientSubCategoryName,PatientTypeName,COUNT(X.Prescription) AS Prescription, 
	SUM(X.Amount) AS SaleAmount,0 AS RefundAmount FROM(
		SELECT CAST(PHM.SaleDate AS DATE) AS PRE_DATE,PHM.SaleId AS Prescription,
		SUM(ROUND(Quantity*ItemRate,0)) AS Amount, PHM.PatientCategoryId AS PatientCategoryId,PHM.PatientSubCategoryId,PatientTypeId FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.SaleId = PHD.SaleId
		WHERE CAST(PHM.SaleDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
		GROUP BY CAST(PHM.SaleDate AS DATE),PHM.SaleId, PHM.PatientCategoryId,PHM.PatientSubCategoryId,PatientTypeId
	)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
		inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and X.PatientSubCategoryId = pt_sb.PatientSubCategoryId
		INNER JOIN SCPStPatientType PT_T ON X.PatientTypeId = PT_T.PatientTypeId
	GROUP BY MONTH(PRE_DATE),Format(PRE_DATE,'MMM-yyyy'),PT_CT.PatientCategoryName,pt_sb.PatientSubCategoryName,PatientTypeName
	)TMP 
	GROUP BY MonthNumbr,Month_Year,PatientCategoryName,PatientSubCategoryName,PatientTypeName 
	ORDER BY MonthNumbr,PatientCategoryName,PatientSubCategoryName,PatientTypeName
 
	end
 
	else
	
	begin
 
	SELECT Month_Year,PatientCategoryName,PatientSubCategoryName,PatientTypeName,SUM(Prescription) AS No_of_SCPTnInPatient,
	SUM(SaleAmount) Total_Sale,SUM(RefundAmount) AS Total_Refunds,SUM(SaleAmount)-SUM(RefundAmount) AS Net_sale FROM
	(
	SELECT MONTH(PHM.SaleRefundDate) AS MonthNumbr,Format(PHM.SaleRefundDate,'MMM-yyyy') Month_Year,
	PatientCategoryName AS PatientCategoryName,PatientSubCategoryName,PatientTypeName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	INNER JOIN SCPTnSale_M PMM ON PMM.SaleId = PHM.SaleId  AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientType PT_T ON PMM.PatientTypeId = PT_T.PatientTypeId
	inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and pmm.PatientSubCategoryId = pt_sb.PatientSubCategoryId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1 and PHM.PatientCategoryId=@PatientCategoryId AND PMM.PatientTypeId=@PatientTypeId
	GROUP BY  MONTH(PHM.SaleRefundDate),Format(PHM.SaleRefundDate,'MMM-yyyy'),PatientCategoryName,PatientSubCategoryName,PatientTypeName
	UNION ALL
	SELECT MONTH(PHM.SaleRefundDate) AS MonthNumbr,Format(PHM.SaleRefundDate,'MMM-yyyy') Month_Year,
	PatientCategoryName AS PatientCategoryName,(CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 
	THEN 'OT' ELSE 'Per' END) AS PatientSubCategoryName,PatientTypeName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientType PT_T ON PMM.PatientTypeId = PT_T.PatientTypeId
	--inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and pmm.PatientSubCategoryId = pt_sb.PatientSubCategoryId
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.SaleRefundId = PHD.SaleRefundId
	WHERE CAST(PHM.SaleRefundDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1  and PatientCategoryId=@PatientCategoryId AND PMM.PatientTypeId=@PatientTypeId
	GROUP BY MONTH(PHM.SaleRefundDate),Format(PHM.SaleRefundDate,'MMM-yyyy'),PatientCategoryName,
	(CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 THEN 'OT' ELSE 'Per' END),PatientTypeName
	UNION ALL
	SELECT MONTH(PRE_DATE) AS MonthNumbr,Format(PRE_DATE,'MMM-yyyy') Month_Year,
	PT_CT.PatientCategoryName  AS PatientCategoryName,pt_sb.PatientSubCategoryName,PatientTypeName,COUNT(X.Prescription) AS Prescription, 
	SUM(X.Amount) AS SaleAmount,0 AS RefundAmount FROM(
		SELECT CAST(PHM.SaleDate AS DATE) AS PRE_DATE,PHM.SaleId AS Prescription,
		SUM(ROUND(Quantity*ItemRate,0)) AS Amount, PHM.PatientCategoryId AS PatientCategoryId,PHM.PatientSubCategoryId,PatientTypeId FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.SaleId = PHD.SaleId
		WHERE CAST(PHM.SaleDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1 and PatientCategoryId=@PatientCategoryId AND PHM.PatientTypeId=@PatientTypeId
		GROUP BY CAST(PHM.SaleDate AS DATE),PHM.SaleId, PHM.PatientCategoryId,PHM.PatientSubCategoryId,PatientTypeId
	)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
		inner join SCPStPatientSubCategory pt_sb on pt_sb.PatientCategoryId = PT_CT.PatientCategoryId and x.PatientSubCategoryId = pt_sb.PatientSubCategoryId
		INNER JOIN SCPStPatientType PT_T ON X.PatientTypeId = PT_T.PatientTypeId
	GROUP BY MONTH(PRE_DATE),Format(PRE_DATE,'MMM-yyyy'),PT_CT.PatientCategoryName,pt_sb.PatientSubCategoryName,PatientTypeName
	)TMP 
	GROUP BY MonthNumbr,Month_Year,PatientCategoryName,PatientSubCategoryName,PatientTypeName 
	ORDER BY MonthNumbr,PatientCategoryName,PatientSubCategoryName,PatientTypeName

	end
 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptOPDSaleDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptOPDSaleDetail]
@FROM_DATE VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

SELECT DATA_DATE,ConsultantName,SUM(MANUAL_ENTRY) AS MANUAL_ENTRY,SUM(QR_ENTRY) AS QR_ENTRY,SUM(TOTAL_AMOUNT) AS TOTAL_AMOUNT FROM
(
SELECT CONVERT(VARCHAR(10),SaleDate, 105) AS DATA_DATE,CONS.ConsultantName,CASE WHEN ISNULL(PatientRegistrationNo,'')='' 
THEN COUNT(DISTINCT PHM.SaleId) ELSE 0 END AS MANUAL_ENTRY,CASE WHEN ISNULL(PatientRegistrationNo,'')!='' 
THEN COUNT(DISTINCT PHM.SaleId) ELSE 0 END AS QR_ENTRY,SUM(ROUND(Quantity*ItemRate,0)) AS TOTAL_AMOUNT FROM SCPTnSale_M PHM
INNER JOIN SCPTnSale_D PHD ON PHD.SaleId = PHM.SaleId
INNER JOIN SCPStConsultant CONS ON PHM.ConsultantId = CONS.HIMSConsultantId
WHERE CAST(SaleDate AS date) BETWEEN CAST(CONVERT(date,@FROM_DATE,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PatientCategoryId=2
GROUP BY CONVERT(VARCHAR(10),SaleDate, 105),ISNULL(PatientRegistrationNo,''),ConsultantName
)TMP GROUP BY DATA_DATE,ConsultantName ORDER BY DATA_DATE,ConsultantName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSCPTnInPatientDetailMedicineDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptInPatientMedicineDetail_D]
@IP AS VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;

select * from (
select  'Sale' as Typee, cast(SL_M.CreatedDate as date) as TRANS_DT,PatientSubCategoryName,
SL_M.SaleId, ItemName, Quantity, SL_D.ItemRate, PaymentTermId, 
isnull(CASE WHEN PaymentTermId = 2 THEN  (SELECT ROUND(Quantity*ItemRate,0) WHERE PaymentTermId = 2) END,0) AS CRTD_SALE,
isnull(CASE WHEN PaymentTermId = 1 THEN  (SELECT ROUND(Quantity*ItemRate,0) WHERE PaymentTermId = 1) END,0) AS CASH_SALE
from SCPTnSale_M SL_M
INNER JOIN SCPTnSale_D SL_D  ON SL_M.SaleId  = SL_D.SaleId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode 
LEFT OUTER JOIN SCPStCompany COM_TYP ON SL_M.CompanyId = COM_TYP.CompanyId
INNER JOIN SCPStPatientType b on SL_M.PatientTypeId = b.PatientTypeId 
INNER JOIN SCPStPatientSubCategory ON SCPStPatientSubCategory.PatientSubCategoryId = SL_M.PatientSubCategoryId
WHERE PatientIp = @IP AND SL_M.IsActive=1
UNION ALL
select 'Refund' as Typee,cast(R_M.SaleRefundDate as date),
CASE WHEN PaymentTermId = 2  AND PatientTypeId= 1 THEN  'OT' ELSE 'Per' END as PatientSubCategoryName,
 R_M.SaleRefundId,
 ItemName, R_D.ReturnQty, R_D.ItemRate, R_D.PaymentTermId, 
 isnull(CASE WHEN PaymentTermId = 2 THEN  (SELECT ReturnAmount WHERE PaymentTermId = 2) END,0) AS CRTD_SALE,
isnull(CASE WHEN PaymentTermId = 1 THEN  (SELECT ReturnAmount WHERE PaymentTermId = 1) END,0) AS CASH_SALE
from SCPTnSaleRefund_M R_M 
INNER JOIN SCPTnSaleRefund_D R_D  ON R_M.SaleRefundId = R_D.SaleRefundId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = R_D.ItemCode 
INNER JOIN SCPTnInPatient PT ON PT.PatientIp = R_M.PatinetIp

WHERE PatinetIp = @IP AND R_M.IsActive=1
)x order by Typee,TRANS_DT   
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSCPTnInPatientDetailMedicineMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptInPatientMedicineDetail_M]

@IP as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

  SELECT PatientIp, PTName,PatientTypeName, CASE WHEN PatientTypeName = 'Private' THEN 'Private' 
WHEN PatientTypeName = 'Corporate' THEN (SELECT TOP 1 COMP.CompanyName FROM SCPStCompany COMP 
LEFT OUTER JOIN SCPTnInPatient ON COMP.CompanyId = SCPTnInPatient.CompanyId WHERE  SCPTnInPatient.PatientIp = X.PatientIp ) 
WHEN CareOffCode = 1 THEN (SELECT TOP 1 'Employee' + ' ' + EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnInPatient ON SCPTnInPatient.CareOff = EMP.EmployeeCode WHERE  SCPTnInPatient.PatientIp =  X.PatientIp)
WHEN CareOffCode = 2 THEN (SELECT TOP 1  'Consultant' + ' ' + CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnInPatient ON SCPTnInPatient.CareOff = CONS.ConsultantId WHERE  SCPTnInPatient.PatientIp =  X.PatientIp)
WHEN CareOffCode = 3 THEN (SELECT  TOP 1 'Partner' + ' ' +  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnInPatient ON SCPTnInPatient.CareOff = PART.PartnerId WHERE  SCPTnInPatient.PatientIp =  X.PatientIp)
 END AS CARECODE FROM (
SELECT PatientIp, (NamePrefix+'. '+FirstName+' '+LastName) as [PTName], SCPTnInPatient.PatientTypeId,CareOff,CareOffCode, PatientTypeName
 FROM SCPTnInPatient
 INNER JOIN SCPStPatientType b on SCPTnInPatient.PatientTypeId = b.PatientTypeId 
  WHERE PatientIp =  @IP
GROUP BY PatientIp, (NamePrefix+'. '+FirstName+' '+LastName),SCPTnInPatient.PatientTypeId,CareOff,CareOffCode,PatientTypeName
)X

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSCPTnInPatientOTSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPatientOTSummary]
@FROM_DT AS VARCHAR(50),@ToDate AS VARCHAR(50)
AS
BEGIN

	SELECT DISTINCT PatientIp,(PT.NamePrefix+'. '+PT.FirstName+' '+PT.LastName) AS SCPTnInPatient_NAME,
	ISNULL(SUM(ROUND(Quantity*ItemRate,0)),0) AS SALE_AMT,
	ISNULL((SELECT SUM(ROUND(ReturnQty*ItemRate,0)) FROM SCPTnSaleRefund_D RD 
	INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId 
	AND RM.PatinetIp=MM.PatientIp AND CAST(RM.CreatedDate AS date) 
	BETWEEN CAST(CONVERT(date,@FROM_DT,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND RD.PaymentTermId=2),0) AS REFUND_AMT FROM SCPTnSale_M MM
	INNER JOIN SCPTnInPatient PT ON PT.PatientIp = MM.PatientIp
	INNER JOIN SCPTnSale_D DD ON MM.SaleId = DD.SaleId 
	WHERE CAST(MM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@FROM_DT,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND MM.PatientTypeId=1 AND MM.PatientSubCategoryId=2
	GROUP BY MM.PatientIp,(PT.NamePrefix+'. '+PT.FirstName+' '+PT.LastName) 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPendingPoBySupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPendingPoBySupplier]
@paramItemTypeId BIGINT,
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
--SELECT  POM.TRNSCTN_ID AS TransectionId,
--	    Supplier.SupplierLongName AS SupplierName,
--		POM.CreatedDate AS CreatedOn
--FROM [dbo].[SCPTnPurchaseOrder_M] AS POM
--INNER JOIN [dbo].[SCPStSupplier] AS Supplier ON Supplier.SupplierId = POM.SupplierId
--LEFT OUTER JOIN [dbo].[SCPTnPharmacyIssuance_M] AS GR ON POM.TRNSCTN_ID = GR.PurchaseOrderId
--WHERE Supplier.ItemTypeId = @paramItemTypeId AND
--	  CAST(POM.CreatedDate as date) BETWEEN 
--	  CAST(CONVERT(date, @paramFromDate,103) as date) AND
--	CAST(CONVERT(date,@paramToDate,103) as date) 


SELECT PurchaseOrderId, PurchaseOrderDate, (DaysLapsed - LeadTime) AS DAYSS ,  convert(varchar(50), SupplierLongName) as  SupplierLongName
 FROM (
SELECT distinct m.PurchaseOrderId, PurchaseOrderDate, LeadTime, SupplierLongName, DATEDIFF(DAY,PurchaseOrderDate , GETDATE()) AS DaysLapsed
  FROM SCPTnPurchaseOrder_M M 
  INNER JOIN SCPStSupplier V ON V.SupplierId = M.SupplierId
  INNER JOIN SCPTnPurchaseOrder_D on SCPTnPurchaseOrder_D.PurchaseOrderId = m.PurchaseOrderId
  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
WHERE  V.ItemTypeId = @paramItemTypeId AND PendingQty>0 and
	  CAST(M.CreatedDate as date) BETWEEN CAST(CONVERT(date, @paramFromDate,103) as date) AND
	CAST(CONVERT(date,@paramToDate,103) as date) AND SCPStItem_M.IsActive=1
)X WHERE DaysLapsed > LeadTime

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPendingPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPendingPR]
@Datee varchar(50),
@itemtype as int
AS
BEGIN

	SET NOCOUNT ON;

 -- select PARENT_TRANS_ID,TRANSCTN_DT, (DaysLapsed - 5) as DaysLapsed, ItemsPending from (
	--SELECT  SCPTnPurchaseRequisition_D.PARENT_TRANS_ID,TRANSCTN_DT,
	--DATEDIFF(DAY,TRANSCTN_DT , GETDATE()) AS DaysLapsed, COUNT(ItemCode) AS ItemsPending
 --   FROM SCPTnPurchaseRequisition_M
 --   INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID = SCPTnPurchaseRequisition_M.TRANSCTN_ID  
	--inner join SCPStWraehouse on SCPStWraehouse.WraehouseId = SCPTnPurchaseRequisition_M.WraehouseId
	--WHERE SCPTnPurchaseRequisition_D.PendingQty>0 and cast(SCPTnPurchaseRequisition_M.CreatedDate as date) <= CAST(CONVERT(date,@Datee,103) as date)
	--and ItemTypeId = @itemtype
	-- GROUP BY  SCPTnPurchaseRequisition_D.PARENT_TRANS_ID,TRANSCTN_DT
	-- )x where x.DaysLapsed > 5

SELECT  PurchaseRequisitionId AS PARENT_TRANS_ID, PurchaseRequisitionDate,  (DaysLapsed - 5) as DaysLapsed , ItemCode  AS ItemsPending FROM ( 
SELECT PurchaseRequisitionId, PurchaseRequisitionDate,ItemCode AS ItemCode, CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END
AS DaysLapsed FROM
(SELECT SCPTnPurchaseRequisition_M.PurchaseRequisitionDate,SCPTnPurchaseRequisition_M.PurchaseRequisitionId, COUNT(SCPTnPurchaseRequisition_D.ItemCode) AS ItemCode
 ,(SELECT TOP 1 DATEDIFF(day,CreatedDate,DecisionDate) FROM SCPTnApproval 
WHERE TransactionDocumentId=SCPTnPurchaseRequisition_M.PurchaseRequisitionId ORDER BY CreatedDate DESC) AS AppDiffDays,
DATEDIFF(day,SCPTnPurchaseRequisition_M.CreatedDate,GETDATE()) As DiffDays FROM SCPTnPurchaseRequisition_M
LEFT OUTER JOIN SCPTnApproval ON SCPTnApproval.TransactionDocumentId = SCPTnPurchaseRequisition_M.PurchaseRequisitionId
INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PurchaseRequisitionId = SCPTnPurchaseRequisition_M.PurchaseRequisitionId
INNER JOIN SCPStItem_M ON SCPTnPurchaseRequisition_D.ItemCode = SCPStItem_M.ItemCode and SCPStItem_M.IsActive=1
WHERE SCPTnPurchaseRequisition_M.ProcurementId= @itemtype AND IsApprove=1  AND SCPTnPurchaseRequisition_D.PendingQty > 0 AND CAST(SCPTnPurchaseRequisition_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,SCPTnPurchaseRequisition_M.CreatedDate,103) as date) AND CAST(CONVERT(date,@Datee,103) as date)
GROUP BY SCPTnPurchaseRequisition_M.PurchaseRequisitionId, SCPTnPurchaseRequisition_M.PurchaseRequisitionDate,SCPTnPurchaseRequisition_M.CreatedDate
)
TMP WHERE 
(CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END) > 5

)X 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPR_SummaryReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPRSummaryReport]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
	--SELECT ItemType.ItemTypeName,
	--	   COUNT(PRM.TRANSCTN_ID) AS No_Of_Pr,
	--	   COUNT(CASE WHEN DATEDIFF(day,PRM.CreatedDate,POD.CreatedDate) <=5  THEN PRM.TRANSCTN_ID END) AS WithinLeadTime,
	--	   COUNT(CASE WHEN  DATEDIFF(day,PRM.CreatedDate,POD.CreatedDate) >5  THEN PRM.TRANSCTN_ID END) AS Pending,
	--	   COUNT(PRDM.TRANSCTN_ID) AS Pr_Discard
	--FROM [dbo].[SCPStItemType] AS ItemType
	--INNER JOIN [SCPTnPurchaseRequisition_M] AS PRM ON PRM.ProcurementId = ItemType.ItemTypeId
	--INNER JOIN [SCPTnPurchaseOrder_D] AS POD ON POD.PurchaseRequisitionId = PRM.TRANSCTN_ID
	--LEFT JOIN [SCPTnPurchaseRequisitionDiscard_M] AS PRDM ON PRM.TRANSCTN_ID = PRDM.PurchaseRequisitionId
	--WHERE  CAST(PRM.CreatedDate as date) BETWEEN 
	--	   CAST(CONVERT(date, @paramFromDate,103) as date) AND
	--	CAST(CONVERT(date,@paramToDate,103) as date) 
	--GROUP BY ItemType.ItemTypeName

SELECT ItemTypeName,COUNT(PRC.PurchaseRequisitionId) AS No_Of_Pr,COUNT(SCPTnPurchaseRequisitionDiscard_M.PurchaseRequisitionId) AS Pr_Discard,
(SELECT COUNT(PC.PurchaseRequisitionId) FROM SCPTnPurchaseRequisition_M PC WHERE PC.IsApprove=1 AND PC.ProcurementId=PRC.ProcurementId
AND PC.PurchaseRequisitionId IN(SELECT PurchaseRequisitionId FROM SCPTnPurchaseOrder_D) AND CAST(PC.CreatedDate AS date) BETWEEN 
CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)) AS WithinLeadTime,
(SELECT COUNT(PurchaseRequisitionId) FROM(SELECT PurchaseRequisitionId,(SELECT TOP 1 DATEDIFF(day,CreatedDate,DecisionDate) FROM SCPTnApproval 
WHERE TransactionDocumentId=SCPTnPurchaseRequisition_M.PurchaseRequisitionId ORDER BY CreatedDate DESC) AS AppDiffDays,
DATEDIFF(day,SCPTnPurchaseRequisition_M.CreatedDate,GETDATE()) As DiffDays FROM SCPTnPurchaseRequisition_M
LEFT OUTER JOIN SCPTnApproval ON SCPTnApproval.TransactionDocumentId = SCPTnPurchaseRequisition_M.PurchaseRequisitionId
WHERE SCPTnPurchaseRequisition_M.ProcurementId=PRC.ProcurementId AND IsApprove=1 AND CAST(SCPTnPurchaseRequisition_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date))TMP WHERE 
(CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END)>5 
AND PRC.PurchaseRequisitionId NOT IN(SELECT PurchaseRequisitionId FROM SCPTnPurchaseOrder_D)) AS Pending FROM SCPTnPurchaseRequisition_M PRC
INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = PRC.ProcurementId
LEFT OUTER JOIN SCPTnPurchaseRequisitionDiscard_M ON SCPTnPurchaseRequisitionDiscard_M.PurchaseRequisitionId = PRC.PurchaseRequisitionId 
AND CAST(SCPTnPurchaseRequisitionDiscard_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date)
WHERE IsApprove=1 AND CAST(PRC.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
AND CAST(CONVERT(date,@paramToDate,103) as date) GROUP BY PRC.ProcurementId,ItemTypeName;

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptPurchaseOrderMonthly]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPurchaseOrderMonthly]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50),
@paramItemTypeId INT
AS
BEGIN
	SELECT COUNT(POM.PurchaseOrderDate) AS No_Of_Po,
		   COUNT(CASE WHEN DATEDIFF(day,POM.CreatedDate,GRM.CreatedDate) <=4  THEN POM.PurchaseOrderDate END) AS Normal,
		   COUNT(CASE WHEN  DATEDIFF(day,POM.CreatedDate,GRM.CreatedDate) >4  THEN POM.PurchaseOrderDate END) AS Pending,
		   COUNT(CASE WHEN POM.IsReject = 1 THEN POM.PurchaseOrderDate END) AS Reject
	FROM [dbo].[SCPTnPurchaseOrder_M] AS POM
	LEFT OUTER JOIN [dbo].[SCPTnGoodReceiptNote_M] AS GRM ON POM.PurchaseOrderDate = GRM.PurchaseOrderId
	INNER JOIN [dbo].[SCPStWraehouse] AS WraehouseName ON POM.WarehouseId = WraehouseName.WraehouseId
	WHERE WraehouseName.ItemTypeId = @paramItemTypeId AND
		  CAST(POM.CreatedDate as date) BETWEEN 
		  CAST(CONVERT(date, @paramFromDate,103) as date) AND
		  CAST(CONVERT(date,@paramToDate,103) as date)
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptQuarterlyItemReturnFromDept]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--SELECT INS.ItemCode, cip.CostPrice, ReturnQty , ins.CreatedDate FROM [SCPTnGoodReturn_D] AS INS
--INNER JOIN CurrentItemPRice AS cip on INS.ItemCode = cip.ItemCode 

--WHERE PARENT_TRNSCTN_ID IN ('RN-1810-00003','RN-1807-00013','RN-1807-00008')
--ORDER BY ins.CreatedDate

CREATE PROCEDURE [dbo].[Sp_SCPRptQuarterlyItemReturnFromDept]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN
		SELECT ItemM.ItemCode AS ItemCode,
			   ItemM.ItemName AS Descriptions,
			   Department.DepartmentName AS Department,
			   GRM.CreatedDate AS CreatedOn,
			   SUM(ItemCurrentPrice.CostPrice*GRD.ReturnQty) AS TotalPrice,
			   ReasonId.ReasonId AS ReasonId
		FROM [dbo].[SCPTnGoodReturn_M] AS GRM
		INNER JOIN [dbo].[SCPStDepartment] AS Department ON GRM.DepartmentId = Department.DepartmentId
		INNER JOIN [dbo].[SCPTnGoodReturn_D] AS GRD ON GRM.GoodReturnId = GRD.GoodReturnId
		INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON GRD.ItemCode = ItemM.ItemCode
		INNER JOIN [dbo].[SCPStRate] AS ItemCurrentPrice ON  ItemCurrentPrice.ItemCode = ItemM.ItemCode
		AND GETDATE() BETWEEN ItemCurrentPrice.FromDate AND ItemCurrentPrice.ToDate
		INNER JOIN [dbo].[SCPStReasonId] AS ReasonId ON GRD.ReturnReasonIdId = ReasonId.ReasonId
		WHERE CAST(GRM.CreatedDate as date) BETWEEN
			  CAST(CONVERT(date,@paramFromDate,103) as date) AND 
			  CAST(CONVERT(date,@paramToDate,103) as date) 

		GROUP BY ReasonId.ReasonId,
				 GRM.CreatedDate,
				 Department.DepartmentName,
				 ItemM.ItemCode,
				 ItemM.ItemName 
END				 



			   
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateAnalysis]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptRateAnalysis]
@FROM_DATE VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

DECLARE @userData TABLE(
    Month_Date VARCHAR(50)
);

DECLARE @FinalData TABLE(
    MonthNumbr INT,
    Year_Month VARCHAR(50),
	Item_Count INT,
	FRST INT,
	SCND INT,
	THRD INT,
	FRTH INT,
	FFTH INT
);

insert into @userData([Month_Date])
    select Format(CR.CreatedDate,'MMM-yyyy') from SCPStRate CR  
	WHERE CAST(CreatedDate AS DATE)>=dateadd(m, datediff (m, 0,CAST(CONVERT(date,@FROM_DATE,103) as date)), 0) 
	AND CAST(CreatedDate AS DATE)<dateadd(m, datediff (m, 0,CAST(CONVERT(date,@ToDate,103) as date))+1, 0)
	group by Format(CR.CreatedDate,'MMM-yyyy')

DECLARE @Date VARCHAR(50);
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(MonthNumbr,Year_Month,Item_Count,FRST,SCND,THRD,FRTH,FFTH)
 SELECT MonthNumbr,Month_Year,COUNT(CC_ItemCode) AS ItemCode,SUM(FRST) AS FRST,SUM(SCND) AS SCND,SUM(THRD) AS THRD
,SUM(FRTH) AS FRTH,SUM(FFTH) AS FFTH  FROM
 (
	 SELECT MonthNumbr,Month_Year,CC_ItemCode,CASE WHEN RATIO <5 THEN 1 ELSE 0 END AS FRST,
	 CASE WHEN RATIO >=5 AND RATIO < 10 THEN 1 ELSE 0 END AS SCND,
	 CASE WHEN RATIO >=10 AND RATIO < 15 THEN 1 ELSE 0 END AS THRD,
	 CASE WHEN RATIO >=15 AND RATIO < 20 THEN 1 ELSE 0 END AS FRTH,
	 CASE WHEN RATIO >=20 THEN 1 ELSE 0 END AS FFTH  FROM
	 (
		SELECT MonthNumbr,Month_Year,CC_ItemCode,(SalePrice-CostPrice)/SalePrice*100 AS RATIO FROM
		(
		   SELECT MONTH(CAST('1.' + Month_Year AS DATETIME)) AS MonthNumbr,Month_Year,CC_ItemCode,CASE WHEN CostPrice IS NULL 
		   THEN (SELECT TOP 1 CostPrice FROM SCPStRate WHERE SCPStRate.ItemCode = CC_ItemCode AND 
		   CAST(SCPStRate.CreatedDate AS date)<DATEADD(M,1,CAST('1.' + Month_Year AS DATETIME)) 
		   ORDER BY SCPStRate.CreatedDate DESC) ELSE CostPrice END CostPrice,CASE WHEN SalePrice IS NULL 
		   THEN (SELECT TOP 1 SalePrice FROM SCPStRate WHERE SCPStRate.ItemCode = CC_ItemCode 
		   AND CAST(SCPStRate.CreatedDate AS date)<DATEADD(M,1,CAST('1.' + Month_Year AS DATETIME)) 
		   ORDER BY SCPStRate.CreatedDate DESC) ELSE SalePrice END SalePrice FROM
		   (
			  SELECT @Date as Month_Year,CC.ItemCode CC_ItemCode,SalePrice,CostPrice FROM SCPStItem_M CC
			  LEFT OUTER JOIN SCPStRate CR ON CC.ItemCode = CR.ItemCode AND Format(CR.CreatedDate,'MMM-yyyy')=@Date
			  WHERE CC.IsActive=1
		   )TMP
		)TMPP
    )TMP
 )TMPP GROUP BY Month_Year,MonthNumbr 
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  

SELECT * FROM @FinalData ORDER BY MonthNumbr

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateChange]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptRateChange]
	@ItemTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

select y.ItemCode, y.ItemName,y.Rate_Count ,y.SalePrice as Current_MRP, RT.SalePrice AS MRP, y.TradePrice as Current_TP, y.CostPrice as Current_PP, rt.TradePrice AS TP, rt.CostPrice AS PP from (
select x.ItemCode,x.ItemName,x.Rate_Count, SalePrice, CostPrice, TradePrice
 from (
select  SCPStRate.ItemCode
, COUNT(SCPStItem_M.ItemCode) AS Rate_Count, 
ItemName from SCPStRate 
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPStRate.ItemCode 
where  DATEDIFF(DAY,SCPStRate.CreatedDate, GETDATE()) < 92 AND ItemTypeId = @ItemTypeId
group by SCPStRate.ItemCode, ItemName
) x inner join SCPStRate RT on RT.ItemCode = x.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
WHERE CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= x.ItemCode )
)y inner join SCPStRate RT on RT.ItemCode = y.ItemCode AND ItemRateId=(select isnull(min(ItemRateId),0) from SCPStRate 
WHERE SCPStRate.ItemCode= y.ItemCode and  DATEDIFF(DAY,SCPStRate.CreatedDate, GETDATE()) < 92)

   
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptRateChangeAnalysis]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPRptRateChangeAnalysis]
@FROM_DATE VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

SELECT MonthNumbr,Month_Year,COUNT(ItemCode) AS ItemCode,SUM(FRST) AS FRST,SUM(SCND) AS SCND,SUM(THRD) AS THRD
,SUM(FRTH) AS FRTH,SUM(FFTH) AS FFTH  FROM
 (
	 SELECT MonthNumbr,Month_Year,ItemCode,CASE WHEN RATIO <5 THEN 1 ELSE 0 END AS FRST,
	 CASE WHEN RATIO >=5 AND RATIO < 10 THEN 1 ELSE 0 END AS SCND,
	 CASE WHEN RATIO >=10 AND RATIO < 15 THEN 1 ELSE 0 END AS THRD,
	 CASE WHEN RATIO >=15 AND RATIO < 20 THEN 1 ELSE 0 END AS FRTH,
	  CASE WHEN RATIO >=20 THEN 1 ELSE 0 END AS FFTH  FROM
	 (
	  SELECT MONTH(CreatedDate) AS MonthNumbr,Format(CreatedDate,'MMM-yyyy') as Month_Year,
	  ItemCode,(SalePrice-CostPrice)/SalePrice*100 AS RATIO FROM SCPStRate 
	  WHERE CAST(CreatedDate AS DATE)>=dateadd(m, datediff (m, 0,CAST(CONVERT(date,@FROM_DATE,103) as date)), 0) 
	  AND CAST(CreatedDate AS DATE)<dateadd(m, datediff (m, 0,CAST(CONVERT(date,@ToDate,103) as date))+1, 0)
	 )TMP
 )TMPP GROUP BY Month_Year,MonthNumbr ORDER BY MonthNumbr

 END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSaleItemTrendQuarterly]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptSaleItemTrendQuarterly]
AS
BEGIN
	DECLARE @NumberOfDays INT;
	SET @NumberOfDays = (SELECT DATEDIFF(day,DATEADD(month, -3, GETDATE()),GETDATE()));
	WITH CTE_QuerterlySale(ItemCategoryName,
						   ItemCode,
						   ItemName,
						   DosageForm,
						   RequiredMonthSale,
						   AvgQty,
						   MinimumParLevel,
						   MaximumParLevel
						  )
	AS
		(SELECT CAST(ItemCat.CategoryName AS varchar) AS ItemCategoryName,
			   ItemM.ItemCode AS ItemCode,
			   ItemM.ItemName AS ItemName,
			   DosageForm.DosageName AS DosageForm,
			   SUM(ItemSale.Quantity) AS RequiredMonthSale,
			   (SELECT TOP(1)AvgPerDay
				FROM [dbo].[SCPStParLevelAssignment_M]
				where ItemCode = ItemM.ItemCode
				ORDER BY ParLevelAssignmentId DESC
				) AS AvgQty,
			   (
				SELECT NewLevel 
				FROM [dbo].[SCPStParLevelAssignment_D] AS ItemD
				where ParLevelAssignmentId IN (SELECT TOP(1)ParLevelAssignmentId FROM [dbo].[SCPStParLevelAssignment_M]
											where ItemCode = ItemM.ItemCode
											ORDER BY ParLevelAssignmentId DESC ) AND ParLevelId = 14
			   ) AS MinimumParLevel,
				(
				SELECT NewLevel 
				FROM [dbo].[SCPStParLevelAssignment_D] AS ItemD
				where ParLevelAssignmentId IN (SELECT TOP(1)ParLevelAssignmentId FROM [dbo].[SCPStParLevelAssignment_M]
											where ItemCode = ItemM.ItemCode
											ORDER BY ParLevelAssignmentId DESC ) AND ParLevelId = 15
			   ) AS MaximumParLevel
		FROM [dbo].[SCPStCategory] AS ItemCat
		INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON ItemCat.CategoryId = ItemM.CategoryId
		INNER JOIN [dbo].[SCPStDosage] AS DosageForm ON ItemM.DosageFormId = DosageForm.DosageId
		INNER JOIn [dbo].[SCPTnSale_D] AS ItemSale ON ItemM.ItemCode = ItemSale.ItemCode
		WHERE  ItemSale.CreatedDate
					 BETWEEN DATEADD(month, -3, GETDATE()) AND GETDATE()
		GROUP By ItemM.ItemName,
				 ItemM.ItemCode,
				 ItemCat.CategoryName,
				 DosageForm.DosageName
		)

	SELECT ItemCategoryName,
		   ItemCode,
		   ItemName,
		   DosageForm,
		   RequiredMonthSale,
		   MinimumParLevel,
		   MaximumParLevel,
		   CAST(Replace(RequiredMonthSale/@NumberOfDays,'.','') AS INT) AS AvgPerDaySale,
		   (CASE WHEN CAST(Replace((RequiredMonthSale/@NumberOfDays)/ISNULL(AvgQty,1),'.','') AS INT) >=12.5  THEN 'FAST MOVING'
		         WHEN CAST(Replace((RequiredMonthSale/@NumberOfDays)/ISNULL(AvgQty,1),'.','') AS INT) <12.5 AND 
					  CAST(Replace((RequiredMonthSale/@NumberOfDays)/ISNULL(AvgQty,1),'.','') AS INT) >=4 THEN 'AVERAGE MOVING'
			     WHEN CAST(Replace((RequiredMonthSale/@NumberOfDays)/ISNULL(AvgQty,1),'.','') AS INT) < 4 THEN 'SLOW MOVING'
		   END) AS Status,
		   AvgQty 
	FROM CTE_QuerterlySale
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptStockGreaterThanMaxLvl]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPRptStockGreaterThanMaxLvl]
@WraehouseId AS INT

AS BEGIN
SELECT TMPPPP.ItemCode,ItemName,MinLevel,MaxLevel,CurrentStock,CostPrice,CurrentStock*CostPrice AS VALUATION,
(CurrentStock-MaxLevel) AS EXCESS_STOCK,(CurrentStock-MaxLevel)*CostPrice AS EXCESS_VALUATION,ItemConsumptionIdTypeName FROM
(
	SELECT TMPPP.ItemCode,ItemName,MinLevel,MaxLevel,CurrentStock,CostPrice,
	CASE WHEN AvgPerDay=0 AND AVG_SALE=0 THEN 0 WHEN AvgPerDay=0 THEN AVG_SALE*100 
	ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM	
	(
		SELECT TMPP.ItemCode,ItemName,MinLevel,MaxLevel,AvgPerDay,TMPP.CurrentStock,CostPrice,
		ROUND(CAST(ISNULL(SUM(Quantity),0) AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()),0) AS AVG_SALE FROM
		(
			SELECT ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,AvgPerDay,CurrentStock,CostPrice FROM
			(
				SELECT SCPStItem_M.ItemCode,ItemName,AvgPerDay,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice,
				SUM(STCK.CurrentStock) AS CurrentStock FROM SCPStItem_M
				INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
				INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId=@WraehouseId
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1) and SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,ItemName,PRIC.CostPrice,AvgPerDay,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
			)TMP 
			GROUP BY ItemCode,ItemName,CurrentStock,CostPrice,AvgPerDay HAVING CurrentStock!=0 and CurrentStock>SUM(MaxLevel)
		)TMPP 
		LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = TMPP.ItemCode
		AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
		GROUP BY TMPP.ItemCode,ItemName,MinLevel,MaxLevel,AvgPerDay,TMPP.CurrentStock,CostPrice
	)TMPPP
)TMPPPP,SCPStStockConsumptionType CT 
WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo 
GROUP BY TMPPPP.ItemCode,ItemName,MinLevel,MaxLevel,CurrentStock,CostPrice,ItemConsumptionIdTypeName ORDER BY EXCESS_VALUATION DESC

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptStockReturnToSupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptStockReturnToSupplier]
@ItemTypeId INT,
@FromDate VARCHAR(50),
@ToDate VARCHAR(50) 	
AS
BEGIN
	
	SET NOCOUNT ON;
		SELECT SupplierLongName,ItemName, SUM(CAST(ReturnQty AS bigint)) AS ItemPackingQuantity,
		sum(NetAmount) as Amount FROM SCPTnReturnToSupplier_D D 
		INNER JOIN SCPTnReturnToSupplier_M M ON D.ReturnToSupplierId = M.ReturnToSupplierId
		INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = M.SupplierId
		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = D.ItemCode
		WHERE itm.ItemTypeId = @ItemTypeId AND cast(M.ReturnToSupplierDate as date) 
		BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date)
		GROUP BY SupplierLongName,ItemName
   
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptSummaryItemDiscountByManufacturer]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSummaryItemDiscountByManufacturer]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50)
AS
BEGIN
SELECT TotalPurchase,DiscountValue,CONVERT(VARCHAR,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))AS PercentageOfDiscountValue
FROM 
(
	SELECT  SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
			SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*TotalAmount) END) DiscountValue ,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
	FROM [dbo].SCPTnGoodReceiptNote_D AS ItemPurchaseD
	INNER JOIN [dbo].SCPStItem_M AS Item ON Item.ItemCode = ItemPurchaseD.ItemCode
	WHERE  CAST(ItemPurchaseD.CreatedDate as date) BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) 
		   AND CAST(CONVERT(date,@paramToDate,103) as date)
	AND Item.ItemTypeId = @paramItemTypeId
)TMP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptUserDispensingComplianceReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPRptUserDispensingComplianceReport]
@DataMonth AS VARCHAR(50)

AS BEGIN

SELECT EmployeeName UserName,SUM(SLIPS) SLIPS,AVG(NULLIF(ONE, 0)) ONE,AVG(NULLIF(TWO, 0)) TWO,AVG(NULLIF(FOUR, 0)) FOUR,
AVG(NULLIF(SIX, 0)) SIX,AVG(NULLIF(EIGHT, 0)) EIGHT,AVG(NULLIF(TEN, 0)) TEN,AVG(NULLIF(OTHER, 0)) OTHER 
FROM(
	SELECT CreatedBy,SUM(TRANS_ID) SLIPS,CASE WHEN ITEMS=1 THEN AVG(TIME_DIFF) ELSE 0 END AS ONE,
	CASE WHEN ITEMS=2 THEN AVG(TIME_DIFF) ELSE 0 END AS TWO,
	CASE WHEN ITEMS=4 THEN AVG(TIME_DIFF) ELSE 0 END AS FOUR,
	CASE WHEN ITEMS=6 THEN AVG(TIME_DIFF) ELSE 0 END AS SIX,
	CASE WHEN ITEMS=8 THEN AVG(TIME_DIFF) ELSE 0 END AS EIGHT,
	CASE WHEN ITEMS=10 THEN AVG(TIME_DIFF) ELSE 0 END AS TEN,
	CASE WHEN ITEMS>10 THEN AVG(TIME_DIFF) ELSE 0 END AS OTHER 
	FROM(
		SELECT CreatedBy,ITEMS,TIME_DIFF,COUNT(SaleId) AS TRANS_ID 
		FROM(
			SELECT MM.CreatedBy,MM.SaleId,COUNT(ItemCode) ITEMS,
			DATEDIFF(S,DifferenceTime,MM.CreatedDate) TIME_DIFF FROM SCPTnSale_M MM
			INNER JOIN SCPTnSale_D DD ON DD.SaleId = MM.SaleId
			WHERE CAST(MM.SaleDate AS DATE)>=DATEADD(m, DATEDIFF (m, 0,CAST(CONVERT(date,@DataMonth,103) as date)), 0) 
	        AND CAST(MM.SaleDate AS DATE)<DATEADD(m, DATEDIFF (m, 0,CAST(CONVERT(date,@DataMonth,103) as date))+1, 0)
			GROUP BY MM.CreatedBy,MM.SaleId,DATEDIFF(S,DifferenceTime,MM.CreatedDate)
		)TMP0 GROUP BY CreatedBy,ITEMS,TIME_DIFF
	)TMP GROUP BY CreatedBy,ITEMS
)TMPP
INNER JOIN SCPStUser_M ON TMPP.CreatedBy = UserId
INNER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode = SCPStUser_M.EmployeeCode
GROUP BY EmployeeName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptVaccineSale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptVaccineSale]
@paramFromDate VARCHAR(50),
@paramToDate VARCHAR(50)
AS
BEGIN

	--SELECT PC.PatientCategoryName AS SCPTnInPatientCat,
	--	  PSC.PatientSubCategoryName SCPTnInPatientSubCategory,
	--	  SCPTnInPatientType.PatientTypeName AS SCPTnInPatientType,
	--	  SaleM.PatientIp AS IP,
	--	  SaleM.FirstName AS SCPTnInPatientName,
	--	  SaleD.SaleId AS InvoiceNo,
	--	  'SALE' AS SaleType,
	--	  ItemM.ItemName AS ItemDesciption,
	--	  SaleD.Quantity AS Qty,
	--	  SaleD.ItemRate AS MRP
	--FROM [dbo].[SCPStPatientCategory] AS PC 
	--INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
	--INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON SaleM.PatientSubCategoryId = PSC.PatientSubCategoryId
	--INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = SaleM.PatientTypeId
	--INNER JOIN [dbo].[SCPTnSale_D] AS SaleD ON SaleD.SaleId = SaleM.SaleId
	--INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON SaleD.ItemCode = ItemM.ItemCode
	--WHERE ItemM.ClassId = 64 AND cast(SaleD.CreatedDate as date) 
	--BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date) 

	--UNION ALL

	--SELECT PC.PatientCategoryName AS SCPTnInPatientCat,
	--	  PSC.PatientSubCategoryName,
	--	  SCPTnInPatientType.PatientTypeName AS SCPTnInPatientType,
	--	  SaleM.PatientIp AS IP,
	--	  SaleM.FirstName AS SCPTnInPatientName,
	--	  RefundM.SaleRefundId AS InvoiceNo,
	--	  'Refund' AS SaleType,
	--	  ItemM.ItemName AS ItemDesciption,
	--	  RefundD.ItemPackingQuantity AS Qty,
	--	  RefundD.ItemRate AS MRP
	--FROM [dbo].[SCPStPatientCategory] AS PC 
	--INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PC.PatientCategoryId = PSC.PatientCategoryId
	--INNER JOIN [dbo].[SCPTnSale_M] AS SaleM ON SaleM.PatientSubCategoryId = PSC.PatientSubCategoryId
	--INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = SaleM.PatientTypeId
	--INNER JOIN [dbo].[SCPTnSaleRefund_M] AS RefundM ON RefundM.SaleRefundId =  SaleM.SaleId
	--INNER JOIN [dbo].[SCPTnSaleRefund_D] AS RefundD ON RefundD.PARENT_TRNSCTN_ID = RefundM.TRNSCTN_ID
	--INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON RefundD.ItemCode = ItemM.ItemCode
	--WHERE ItemM.ClassId = 64 AND cast(SaleM.CreatedDate as date) 
	--BETWEEN CAST(CONVERT(date,@paramFromDate,103) as date) AND CAST(CONVERT(date,@paramToDate,103) as date) 

	    SELECT SCPTnInPatientType,SCPTnInPatientCat,SCPTnInPatientSubCategory,SUM(SL_QTY) AS SL_QTY,SUM(SL_AMOUNT) AS SL_AMOUNT,
	ISNULL(SUM(ReturnQty),0) AS ReturnQty,ISNULL(SUM(ReturnAmount),0) AS ReturnAmount FROM 
	(
	SELECT SCPStPatientCategory.PatientCategoryName AS SCPTnInPatientCat,PSC.PatientSubCategoryName SCPTnInPatientSubCategory,
		  SCPTnInPatientType.PatientTypeName AS SCPTnInPatientType,SUM(Quantity) AS SL_QTY,SUM(Quantity*ItemRate) AS SL_AMOUNT,
		  (SELECT SUM(ReturnQty) FROM SCPTnSaleRefund_M INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.SaleRefundId = SCPTnSaleRefund_M.SaleRefundId 
		  WHERE SCPTnSaleRefund_M.PatinetIp=PHM.PatientIp AND CAST(CONVERT(date,SCPTnSaleRefund_M.SaleRefundDate,103) as date)=CAST(CONVERT(date,PHM.SaleDate,103) as date)) AS ReturnQty,
		  (SELECT SUM(ReturnAmount) FROM SCPTnSaleRefund_M INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.SaleRefundId = SCPTnSaleRefund_M.SaleRefundId 
		  WHERE SCPTnSaleRefund_M.PatinetIp=PHM.PatientIp AND CAST(CONVERT(date,SCPTnSaleRefund_M.SaleRefundDate,103) as date)=CAST(CONVERT(date,PHM.SaleDate,103) as date)) AS ReturnAmount FROM SCPTnSale_M PHM
	INNER JOIN SCPStPatientCategory ON PHM.PatientCategoryId = SCPStPatientCategory.PatientCategoryId
	INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PHM.PatientSubCategoryId = PSC.PatientSubCategoryId
    INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = PHM.PatientTypeId
	INNER JOIN [dbo].[SCPTnSale_D] AS SaleD ON SaleD.SaleId = PHM.SaleId
	INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON SaleD.ItemCode = ItemM.ItemCode
	WHERE ItemM.ClassId = 2 AND PHM.PatientIp!='0'
	GROUP BY PHM.PatientIp,PHM.SaleDate,SCPStPatientCategory.PatientCategoryName,PSC.PatientSubCategoryName,SCPTnInPatientType.PatientTypeName
	UNION
	SELECT SCPStPatientCategory.PatientCategoryName AS SCPTnInPatientCat,PSC.PatientSubCategoryName SCPTnInPatientSubCategory,
		  SCPTnInPatientType.PatientTypeName AS SCPTnInPatientType,SUM(Quantity) AS SL_QTY,SUM(Quantity*ItemRate) AS SL_AMOUNT,
		  (SELECT SUM(ReturnQty) FROM SCPTnSaleRefund_M INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.SaleRefundId = SCPTnSaleRefund_M.SaleRefundId 
		  WHERE SCPTnSaleRefund_M.SaleId=PHM.SaleId AND CAST(CONVERT(date,SCPTnSaleRefund_M.SaleRefundDate,103) as date)=CAST(CONVERT(date,PHM.SaleDate,103) as date)) AS ReturnQty,
		  (SELECT SUM(ReturnAmount) FROM SCPTnSaleRefund_M INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.SaleRefundId = SCPTnSaleRefund_M.SaleRefundId 
		  WHERE SCPTnSaleRefund_M.SaleId=PHM.SaleId  AND CAST(CONVERT(date,SCPTnSaleRefund_M.SaleRefundDate,103) as date)=CAST(CONVERT(date,PHM.SaleDate,103) as date)) AS ReturnAmount FROM SCPTnSale_M PHM
	INNER JOIN SCPStPatientCategory ON PHM.PatientCategoryId = SCPStPatientCategory.PatientCategoryId
	INNER JOIN [dbo].[SCPStPatientSubCategory] AS PSC ON PHM.PatientSubCategoryId = PSC.PatientSubCategoryId
    INNER JOIN [dbo].[SCPStPatientType] AS SCPTnInPatientType ON SCPTnInPatientType.PatientTypeId = PHM.PatientTypeId
	INNER JOIN [dbo].[SCPTnSale_D] AS SaleD ON SaleD.SaleId = PHM.SaleId
	INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON SaleD.ItemCode = ItemM.ItemCode
	WHERE ItemM.ClassId = 2 AND PHM.PatientIp='0' AND CAST(CONVERT(date,PHM.SaleDate,103) as date)
	BETWEEN CAST(CONVERT(date,@paramToDate,103) as date) AND CAST(CONVERT(date,@paramFromDate,103) as date)
	GROUP BY PHM.SaleId,PHM.SaleDate,SCPStPatientCategory.PatientCategoryName,PSC.PatientSubCategoryName,SCPTnInPatientType.PatientTypeName
	)TMP GROUP BY SCPTnInPatientType,SCPTnInPatientCat,SCPTnInPatientSubCategory
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptVendorChartWiseInventory]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	
	CREATE PROC [dbo].[Sp_SCPRptVendorChartWiseInventory]
	@WraehouseId AS INT
	AS BEGIN
	
	SELECT VendorChart,COUNT(DISTINCT ItemCode) Items,
	SUM(CurrentStock*CurrentItemPrice) AS StockValue FROM
	(
		SELECT ISNULL(VendorChart,'None') AS VendorChart,CC.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,
		CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END CurrentItemPrice 
		FROM SCPStItem_M CC
		LEFT JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = CC.ItemCode AND ItemSupplierMappingId=(SELECT TOP 1 ItemSupplierMappingId FROM SCPStItem_D_Supplier 
		WHERE SCPStItem_D_Supplier.ItemCode=CC.ItemCode AND DefaultVendor=1 ORDER BY CreatedDate DESC)
		LEFT JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId 
		LEFT JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
		INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = CC.ItemCode AND WraehouseId=@WraehouseId
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=CC.ItemCode)
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
		WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
 		WHERE CC.IsActive=1 AND CurrentStock!=0 --order by ItemCode,BatchNo
	)TMP GROUP BY VendorChart ORDER BY VendorChart

	END
	

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptVndrMnfctrDiscountDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPRptVndrMnfctrDiscountDetail] 
@SelectionID AS INT,
@VndrOrMnfctrId AS INT,
@From As varchar(12),
@To As varchar(12)

AS BEGIN

IF @SelectionID=1 
BEGIN
	SELECT ItemCode,ItemName,SUM(RecievedQty) RecievedQty,ItemRate,ISNULL(AVG(DISCOUNT_PER),0) DISCOUNT,SUM(ROUND(Amount,0)) Amount 
	FROM(
		SELECT ItemCode,ItemName,SUM(RecievedQty) RecievedQty,ItemRate,ISNULL(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN),0) AS DISCOUNT,
		SUM(TMP.NetAmount) Amount,(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN)/SUM(TMP.TotalAmount)*100)+AVG(TP_DISC) DISCOUNT_PER
		FROM(
			SELECT GRD.GoodReceiptNoteDetailId,GRD.ItemCode,ItemName,RecievedQty,TradePrice,GRD.ItemRate,
			((RecievedQty*PRIC.TradePrice-GRD.TotalAmount)/(RecievedQty*PRIC.TradePrice))*100 TP_DISC,
			BonusQty*GRD.ItemRate as BonusAmount,GRD.TotalAmount,(GRD.TotalAmount-GRD.AfterDiscountAmount) as DISCOUNT_GRN ,
			GRD.NetAmount FROM SCPTnGoodReceiptNote_D GRD 
			INNER JOIN SCPStItem_M ON GRD.ItemCode = SCPStItem_M.ItemCode 
			INNER JOIN SCPTnGoodReceiptNote_M ON GRD.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId 
			AND IsApproved=1 AND SCPTnGoodReceiptNote_M.IsActive=1
			INNER JOIN SCPTnPurchaseOrder_M ON SCPTnGoodReceiptNote_M.PurchaseOrderId = SCPTnPurchaseOrder_M.PurchaseOrderId
		    LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = GRD.ItemCode AND SCPTnPurchaseOrder_M.PurchaseOrderDate 
			BETWEEN FromDate AND ToDate AND PRIC.CostPrice = GRD.ItemRate
		    WHERE CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) BETWEEN CAST(CONVERT(date,@From,103) as date) 
			AND CAST(CONVERT(date,@To,103) as date) AND ManufacturerId=@VndrOrMnfctrId AND SCPTnGoodReceiptNote_M.GRNType!=2
		)TMP GROUP BY ItemCode,ItemName,ItemRate 
	)TMPP --Where TMPP.DISCOUNT !=0 
	GROUP BY ItemCode,ItemName,ItemRate  ORDER BY ItemCode
END
ELSE IF @SelectionID=2
BEGIN
	SELECT ItemCode,ItemName,SUM(RecievedQty) RecievedQty,ItemRate,AVG(DISCOUNT_PER) DISCOUNT,SUM(ROUND(Amount,0)) Amount 
	FROM(
		SELECT ItemCode,ItemName,SUM(RecievedQty) RecievedQty,ItemRate,ISNULL(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN),0) AS DISCOUNT,
		SUM(TMP.NetAmount) Amount,(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN)/SUM(TMP.TotalAmount)*100)+AVG(TP_DISC) DISCOUNT_PER
		FROM(
			SELECT GRD.GoodReceiptNoteDetailId,GRD.ItemCode,ItemName,RecievedQty,TradePrice,GRD.ItemRate,
			((RecievedQty*PRIC.TradePrice-GRD.TotalAmount)/(RecievedQty*PRIC.TradePrice))*100 TP_DISC,
			BonusQty*GRD.ItemRate as BonusAmount,GRD.TotalAmount,(GRD.TotalAmount-GRD.AfterDiscountAmount) as DISCOUNT_GRN ,
			GRD.NetAmount FROM SCPTnGoodReceiptNote_D GRD
			INNER JOIN SCPStItem_M ON GRD.ItemCode = SCPStItem_M.ItemCode 
			INNER JOIN SCPTnGoodReceiptNote_M ON GRD.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId AND IsApproved=1 AND SCPTnGoodReceiptNote_M.IsActive=1
			INNER JOIN SCPTnPurchaseOrder_M ON SCPTnGoodReceiptNote_M.PurchaseOrderId = SCPTnPurchaseOrder_M.PurchaseOrderId
		    LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = GRD.ItemCode AND SCPTnPurchaseOrder_M.PurchaseOrderDate BETWEEN FromDate AND ToDate AND PRIC.CostPrice = GRD.ItemRate
		    WHERE CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) BETWEEN CAST(CONVERT(date,@From,103) as date) 
			AND CAST(CONVERT(date,@To,103) as date) AND SCPTnGoodReceiptNote_M.SupplierId=@VndrOrMnfctrId AND SCPTnGoodReceiptNote_M.GRNType!=2
		)TMP GROUP BY ItemCode,ItemName,ItemRate 
	)TMPP --Where TMPP.DISCOUNT !=0 
	GROUP BY ItemCode,ItemName,ItemRate  ORDER BY ItemCode
END

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptVndrMnfctrDiscountSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPRptVndrMnfctrDiscountSummary] 
@SelectionID AS INT,
@From As varchar(12),
@To As varchar(12)
AS BEGIN

IF @SelectionID=1 
BEGIN
SELECT TMPP.ManufacturerName AS Description,
COUNT(TMPP.ItemCode) AS Items,ISNULL(AVG(DISCOUNT_PER),0) AS DISCOUNT, SUM(ROUND(Amount,0)) AS Amount FROM 
(
	SELECT  ManufacturerName ,TMP.ItemCode,ISNULL(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN),0) AS DISCOUNT,
	SUM(TMP.NetAmount) Amount,(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN)/SUM(TMP.TotalAmount)*100)+AVG(TP_DISC) DISCOUNT_PER
	FROM(
		SELECT ManufacturerName,GRD.GoodReceiptNoteDetailId,GRD.ItemCode,
		
		((RecievedQty*PRIC.TradePrice-GRD.TotalAmount)/(RecievedQty*PRIC.TradePrice))*100 TP_DISC,
		BonusQty*GRD.ItemRate as BonusAmount,GRD.TotalAmount,(GRD.TotalAmount-GRD.AfterDiscountAmount) as DISCOUNT_GRN ,
		GRD.NetAmount FROM SCPTnGoodReceiptNote_D GRD
		INNER JOIN SCPTnGoodReceiptNote_M ON GRD.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId 
		AND IsApproved=1 AND SCPTnGoodReceiptNote_M.IsActive=1
		INNER JOIN SCPStItem_M ON GRD.ItemCode = SCPStItem_M.ItemCode
		INNER JOIN SCPStManufactutrer ON SCPStManufactutrer.ManufacturerId = SCPStItem_M.ManufacturerId
		INNER JOIN SCPTnPurchaseOrder_M ON SCPTnGoodReceiptNote_M.PurchaseOrderId = SCPTnPurchaseOrder_M.PurchaseOrderId
		LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = GRD.ItemCode AND SCPTnPurchaseOrder_M.PurchaseOrderDate 
		BETWEEN FromDate AND ToDate AND PRIC.CostPrice = GRD.ItemRate
		WHERE CAST(GRD.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@From,103) as date)
		AND CAST(CONVERT(date,@To,103) as date)  AND SCPTnGoodReceiptNote_M.GRNType!=2
	)TMP GROUP BY ManufacturerName , TMP.ItemCode
	)TMPP-- where TMPP.DISCOUNT !=0 
	GROUP BY ManufacturerName

END
ELSE IF @SelectionID=2
BEGIN
SELECT TMPP.SupplierLongName AS Description,
COUNT(TMPP.ItemCode) AS Items,ISNULL(AVG(DISCOUNT_PER),0) AS DISCOUNT, SUM(ROUND(Amount,0)) AS Amount FROM 
(

SELECT SupplierLongName,TMP.ItemCode,ISNULL(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN),0) AS DISCOUNT,
	SUM(TMP.NetAmount) Amount,(SUM(TMP.TP_DISC+TMP.BonusAmount+DISCOUNT_GRN)/SUM(TMP.TotalAmount)*100)+AVG(TP_DISC) DISCOUNT_PER
	FROM(
		SELECT SupplierLongName,GRD.GoodReceiptNoteDetailId,GRD.ItemCode,TradePrice,GRD.ItemRate,
		((RecievedQty*PRIC.TradePrice-GRD.TotalAmount)/(RecievedQty*PRIC.TradePrice))*100 TP_DISC,
		BonusQty*GRD.ItemRate as BonusAmount,GRD.TotalAmount,(GRD.TotalAmount-GRD.AfterDiscountAmount) as DISCOUNT_GRN ,
		GRD.NetAmount FROM SCPTnGoodReceiptNote_D GRD
		INNER JOIN SCPTnGoodReceiptNote_M ON GRD.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId AND IsApproved=1 AND SCPTnGoodReceiptNote_M.IsActive=1
		INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId = SCPTnGoodReceiptNote_M.SupplierId
		INNER JOIN SCPTnPurchaseOrder_M ON SCPTnGoodReceiptNote_M.PurchaseOrderId = SCPTnPurchaseOrder_M.PurchaseOrderId
		LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = GRD.ItemCode AND SCPTnPurchaseOrder_M.PurchaseOrderDate BETWEEN FromDate AND ToDate AND PRIC.CostPrice = GRD.ItemRate
		WHERE CAST(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate AS date) BETWEEN CAST(CONVERT(date,@From,103) as date) 
		AND CAST(CONVERT(date,@TO,103) as date) AND SCPTnGoodReceiptNote_M.GRNType!=2
	)TMP GROUP BY SupplierLongName,ItemCode
	)TMPP --where TMPP.DISCOUNT !=0 
	GROUP BY SupplierLongName




END

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRptWaitingPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptWaitingPR]
@Datee varchar(50),
 @itemtype as int

AS
BEGIN
	
	SET NOCOUNT ON;
--select * from (
--	SELECT DISTINCT SCPTnPurchaseRequisition_M.TRANSCTN_ID,TRANSCTN_DT,DATEDIFF(DAY,TRANSCTN_DT , GETDATE()) AS DaysLapsed
--    FROM SCPTnPurchaseRequisition_M
--    INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID = SCPTnPurchaseRequisition_M.TRANSCTN_ID 
--	INNER JOIN SCPTnPurchaseOrder_D ON SCPTnPurchaseOrder_D.PurchaseRequisitionId !=  SCPTnPurchaseRequisition_M.TRANSCTN_ID 
--	inner join SCPStWraehouse on SCPStWraehouse.WraehouseId = SCPTnPurchaseRequisition_M.WraehouseId
--	WHERE SCPTnPurchaseRequisition_D.PendingQty>0 and cast(SCPTnPurchaseRequisition_M.CreatedDate as date)  <=  CAST(CONVERT(date,@Datee,103) as date)
--	--BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
--	-- and CAST(CONVERT(date,@ToDate,103) as date) 
--	and ItemTypeId = @itemtype
--	 and SCPTnPurchaseRequisition_M.IsApprove = 1
--	 )x where x.DaysLapsed <=5

	 SELECT PurchaseRequisitionId, PurchaseRequisitionDate, CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END
	  AS DaysLapsed FROM
(SELECT distinct PurchaseRequisitionDate,SCPTnPurchaseRequisition_M.PurchaseRequisitionId,(SELECT TOP 1 DATEDIFF(day,CreatedDate,DecisionDate) FROM SCPTnApproval 
WHERE TransactionDocumentId=SCPTnPurchaseRequisition_M.PurchaseRequisitionId ORDER BY CreatedDate DESC) AS AppDiffDays,
DATEDIFF(day,SCPTnPurchaseRequisition_M.CreatedDate,GETDATE()) As DiffDays FROM SCPTnPurchaseRequisition_M
LEFT OUTER JOIN SCPTnApproval ON SCPTnApproval.TransactionDocumentId = SCPTnPurchaseRequisition_M.PurchaseRequisitionId
INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PurchaseRequisitionId = SCPTnPurchaseRequisition_M.PurchaseRequisitionId
WHERE SCPTnPurchaseRequisition_M.ProcurementId= @itemtype AND IsApprove=1  AND SCPTnPurchaseRequisition_D.PendingQty > 0 AND CAST(SCPTnPurchaseRequisition_M.CreatedDate AS date) 
BETWEEN CAST(CONVERT(date,SCPTnPurchaseRequisition_M.CreatedDate,103) as date) AND CAST(CONVERT(date,@Datee,103) as date))
TMP WHERE 
(CASE WHEN AppDiffDays IS NULL THEN DiffDays ELSE (DiffDays-AppDiffDays) END) <= 5 
END

GO
/****** Object:  StoredProcedure [dbo].[RptBatchNoDetailReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptBatchNoDetailReport]
@BatchNo AS VARCHAR(50)
AS
BEGIN
	 SELECT T_DATE,PatientIp,T_TYPE,SaleId,SCPTnInPatientName,PatientTypeName,PAYMENT_TERM,ItemCode,ItemName,Quantity,ItemRate,Amount FROM    
		(
			SELECT 'Sale' AS T_TYPE,PH_M.CreatedDate AS T_DATE, PH_M.SaleId,PaymentTermName AS PAYMENT_TERM,PH_M.PatientIp,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName AS SCPTnInPatientName,PH_D.ItemCode, 
			PH_D.ItemRate,SUM(ROUND(PH_D.Quantity*PH_D.ItemRate,0)) AS Amount, SUM(PH_D.Quantity) AS Quantity, ItemName FROM SCPTnSale_M PH_M
			INNER JOIN SCPTnSale_D PH_D ON PH_M.SaleId = PH_D.SaleId
			INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
			INNER JOIN SCPStPatientType PT_TYP ON PH_M.PatientTypeId = PT_TYP.PatientTypeId 
			INNER JOIN SCPStPaymentTerm ON SCPStPaymentTerm.PaymentTermId = PH_D.PaymentTermId
			WHERE  PH_M.BatchNo=@BatchNo
		    GROUP BY PH_M.CreatedDate, PH_M.SaleId, PH_M.PatientIp, PH_M.BatchNo,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName, 
			PH_D.ItemCode, PH_D.ItemRate, ItemName,PaymentTermName
			UNION ALL
			SELECT 'Refund',PH_M.CreatedDate AS T_DATE, PH_M.SaleRefundId,PaymentTermName AS PAYMENT_TERM,PH_M.PatinetIp, 
			PT_TYP.PatientTypeName, SCPTnInPatient.NamePrefix +' '+ SCPTnInPatient.FirstName +' '+ SCPTnInPatient.LastName AS SCPTnInPatientName, 
			PH_D.ItemCode, PH_D.ItemRate, (PH_D.ReturnAmount*-1), PH_D.ReturnQty AS Quantity, ItemName FROM SCPTnSaleRefund_M PH_M
			INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.SaleRefundId = PH_D.SaleRefundId
			INNER JOIN SCPTnInPatient ON SCPTnInPatient.PatientIp = PH_M.PatinetIp
			INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
			INNER JOIN SCPStPatientType PT_TYP ON SCPTnInPatient.PatientTypeId = PT_TYP.PatientTypeId 
			INNER JOIN SCPStPaymentTerm ON PH_D.PaymentTermId = SCPStPaymentTerm.PaymentTermId
			WHERE  PH_M.BatchNo=@BatchNo
  		    UNION ALL
			SELECT DISTINCT 'Refund' AS T_TYPE,PH_M.CreatedDate AS T_DATE, PH_M.SaleId,PaymentTermName AS PAYMENT_TERM,PH_M.PatinetIp, 
			PT_TYP.PatientTypeName, SCPTnSale_M.NamePrefix +' '+ SCPTnSale_M.FirstName +' '+ SCPTnSale_M.LastName AS SCPTnInPatientName, 
			PH_D.ItemCode, PH_D.ItemRate, (PH_D.ReturnAmount*-1), PH_D.ReturnQty AS Quantity, ItemName FROM SCPTnSaleRefund_M PH_M
			INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.SaleRefundId = PH_D.SaleRefundId
			INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = PH_M.SaleId AND PatinetIp='0' AND SCPTnSale_M.SaleId!='0'
			INNER JOIN SCPTnSale_D ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId AND SCPTnSale_D.ItemCode = PH_D.ItemCode
			INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
			INNER JOIN SCPStPatientType PT_TYP ON SCPTnSale_M.PatientTypeId = PT_TYP.PatientTypeId 
			INNER JOIN SCPStPaymentTerm ON PaymentTermId = PaymentTermId
			WHERE  PH_M.BatchNo=@BatchNo
		)TMP ORDER BY T_DATE
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR001_1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPItemExpiryAlert]
@UserId AS INT
AS
BEGIN

	 DECLARE @OLD_COUNT AS INT,@NEW_COUNT AS INT
  SET @OLD_COUNT = ISNULL((SELECT AlertCount FROM SCPTnAlert_M WHERE AlertTypeId=1 AND Status=0),0)
  SET @NEW_COUNT = (SELECT COUNT(ItemCode) AS EXPRY_ITM  FROM
  (
   SELECT DISTINCT ItemCode FROM
   (
    SELECT SCPTnStock_M.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,max(SCPTnGoodReceiptNote_D.ExpiryDate) AS EXP_DATE FROM SCPTnStock_M
    INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
    AND SCPTnStock_M.WraehouseId=3 GROUP BY SCPTnStock_M.ItemCode,CurrentStock,SCPTnStock_M.BatchNo
	 )TMP WHERE CurrentStock>0 AND EXP_DATE BETWEEN CONVERT(DATE,GETDATE()) AND DATEADD(month,6, CONVERT(DATE,GETDATE()))
  )TT)

  IF (@OLD_COUNT < @NEW_COUNT)
  BEGIN
  UPDATE SCPTnAlert_M SET Status=1  WHERE AlertTypeId=1 AND Status=0 --WHERE AlertId=(SELECT TOP 1 AlertId FROM SCPTnAlert_M WHERE AlertTypeId=1 AND Status=0 ORDER BY AlertId DESC)
  SELECT '0' AS AlertId,@NEW_COUNT AS AlertCount,1 AS AlertTypeId
  END
  ELSE
  BEGIN
  UPDATE SCPTnAlert_M SET AlertCount=@NEW_COUNT WHERE AlertTypeId=1 AND Status=0 --WHERE AlertId=(SELECT TOP 1 AlertId FROM SCPTnAlert_M WHERE AlertTypeId=1 AND Status=0 ORDER BY AlertId DESC)
  SELECT SCPTnAlert_M.AlertId,AlertCount,1 AS AlertTypeId FROM SCPTnAlert_M 
  INNER JOIN SCPTnAlert_D ON SCPTnAlert_D.AlertId=SCPTnAlert_M.AlertId
  WHERE AlertTypeId=1 AND Status=0 AND SCPTnAlert_D.UserId=@UserId AND SCPTnAlert_D.IsView = 0
  END

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR001_2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPItemExpiredAlert]
	
	@UserId AS INT
	AS
BEGIN
	
	SET NOCOUNT ON;
		 DECLARE @OLD_COUNT AS INT,@NEW_COUNT AS INT
  SET @OLD_COUNT = ISNULL((SELECT AlertCount FROM SCPTnAlert_M WHERE AlertTypeId=2 AND Status=0),0)
  SET @NEW_COUNT = (SELECT COUNT(ItemCode) AS EXPRY_ITM  FROM(
  SELECT DISTINCT ItemCode FROM 
(
  SELECT SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock,
  MAX(SCPTnStock_M.CreatedDate) AS ISSUE_DATE,MAX(SCPTnGoodReceiptNote_D.ExpiryDate) EXP_DATE FROM SCPStItem_M
  INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode=SCPTnStock_M.ItemCode AND SCPTnStock_M.WraehouseId=3
  INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode AND SCPTnStock_M.BatchNo=SCPTnPharmacyIssuance_D.BatchNo
  GROUP BY SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock
)
 TMP WHERE CurrentStock>0 AND EXP_DATE<GETDATE()
  )TT
  )

  IF (@OLD_COUNT < @NEW_COUNT)
  BEGIN
  UPDATE SCPTnAlert_M SET Status=1  WHERE AlertTypeId=2 AND Status=0 --WHERE AlertId=(SELECT TOP 1 AlertId FROM SCPTnAlert_M WHERE AlertTypeId=1 AND Status=0 ORDER BY AlertId DESC)
  SELECT '0' AS AlertId,@NEW_COUNT AS AlertCount,2 AS AlertTypeId
  END
  ELSE
  BEGIN
  UPDATE SCPTnAlert_M SET AlertCount=@NEW_COUNT WHERE AlertTypeId=2 AND Status=0 --WHERE AlertId=(SELECT TOP 1 AlertId FROM SCPTnAlert_M WHERE AlertTypeId=1 AND Status=0 ORDER BY AlertId DESC)
  SELECT SCPTnAlert_M.AlertId,AlertCount,2 AS AlertTypeId FROM SCPTnAlert_M 
  INNER JOIN SCPTnAlert_D ON SCPTnAlert_D.AlertId=SCPTnAlert_M.AlertId
  WHERE AlertTypeId=2 AND Status=0 AND SCPTnAlert_D.UserId= @UserId AND SCPTnAlert_D.IsView = 0
  END
   
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR001_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateAlertNo]
AS
BEGIN
	SELECT 'AL-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(CreatedDate)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnAlert_M
	WHERE MONTH(CreatedDate) = MONTH(getdate())
    AND YEAR(CreatedDate) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR001_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetAlerts]
@UserId AS INT
AS
BEGIN
	SET NOCOUNT ON;
SELECT AlertType, SCPStAlertType_D.AlertTypeId,  SCPStAlertType_D.UserId, IsView, ShowLaterCount, SCPTnAlert_M.AlertId,
CASE WHEN SCPStAlertType_D.AlertTypeId = 1 THEN (SELECT CONCAT(AlertCount ,'  Items will be expired with in 6 months') )
WHEN SCPStAlertType_D.AlertTypeId = 2 THEN (SELECT CONCAT(AlertCount ,'  Expired Items') )  END  AS ALERT_TXT
 FROM SCPStAlertType_D INNER JOIN SCPStAlertType_M ON SCPStAlertType_D.AlertTypeId= SCPStAlertType_M.AlertTypeId
 INNER JOIN SCPTnAlert_M ON SCPTnAlert_M.AlertTypeId = SCPStAlertType_M.AlertTypeId
 INNER JOIN SCPTnAlert_D ALT_D ON ALT_D.AlertId = SCPTnAlert_M.AlertId AND ALT_D.UserId=SCPStAlertType_D.UserId
 Where SCPStAlertType_D.UserId = @UserId AND SCPTnAlert_M.Status = 0 
 order by AlertTypeId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR002_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAlertsFrUser]
@AlertTypeId AS INT
AS
BEGIN
	 SELECT UserId,DepartmentId FROM SCPStAlertType_M
     INNER JOIN SCPStAlertType_D ON SCPStAlertType_M.AlertTypeId = SCPStAlertType_D.AlertTypeId 
     WHERE SCPStAlertType_M.AlertTypeId = @AlertTypeId 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR002_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAlertTypeFrUser] 
@UserId AS INT
AS
BEGIN
	SELECT AlertTypeId,DepartmentId FROM SCPStAlertType_D WHERE UserId=@UserId 
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPALR002_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalAlertFrUser] 
@UserId AS INT
AS
BEGIN
select count(*) as COUNT, SCPTnAlert_M.AlertTypeId 
from SCPStAlertType_D inner join SCPTnAlert_M 
on SCPTnAlert_M.AlertTypeId = SCPStAlertType_D.AlertTypeId 
INNER JOIN SCPTnAlert_D ON SCPTnAlert_D.AlertId = SCPTnAlert_M.AlertId AND SCPTnAlert_D.UserId = SCPStAlertType_D.UserId
where SCPTnAlert_D.UserId= @UserId and Status = 0 AND SCPTnAlert_D.IsView = 0
GROUP BY SCPTnAlert_M.AlertTypeId
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAntibioticSaleList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptAntibioticSaleList] 
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN
	SELECT SCPTnSale_M.SaleId,CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPStConsultant.ConsultantName,
	NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,SCPStPatientCategory.PatientCategoryName AS PatientTypeName,SCPStDosage.DosageName,
    SCPStItem_M.ItemName,SCPTnSale_D.Quantity,SCPStManufactutrer.ManufacturerName,SCPTnSale_M.BatchNo,SCPStUser_M.UserName FROM SCPTnSale_M
    INNER JOIN SCPStConsultant ON SCPStConsultant.ConsultantId = SCPTnSale_M.ConsultantId
	INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
    INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnSale_D.ItemCode
  	INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
    INNER JOIN SCPStManufactutrer ON SCPStManufactutrer.ManufacturerId=SCPStItem_M.ManufacturerId
    INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
    INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId
    WHERE SCPStItem_M.ClassId=49 AND cast(SCPTnSale_M.TRANS_DT as date)
	BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date)
	AND SCPTnSale_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnApproval_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetRecievedPendingApprovals]
@UserId as int
AS
BEGIN

   SELECT * FROM
   (
		Select SCPStUser_M.UserName as FromUser,SCPTnApproval.TransactionDocumentId,SCPTnApproval.TransactionDocumentId,SCPTnApproval.CreatedDate,SCPTnApproval.FormCode,
		case When isnull(SCPTnApproval.IsApproved,0)=0 AND isnull(SCPTnApproval.IsRejectED,0)=0 then 'Pending' end as AppStatus from SCPTnApproval 
		INNER JOIN SCPStUser_M ON SCPTnApproval.FromUser = SCPStUser_M.UserId where SCPTnApproval.IsApproved=0 AND SCPTnApproval.IsRejectED=0
		and ToUSer=@UserId --ORDER BY SCPTnApproval.CreatedDate DESC
		UNION ALL
		SELECT SCPStUser_M.UserName as FromUser,PRD.ItemCode+' '+ItemName AS TransactionDocumentId,CAST(PRD.GoodReceiptDetailId AS VARCHAR(50)) AS TransactionDocumentId,
		PRD.CreatedDate,'Views/CentralRepository/SCPStRate' AS FormCode,case When isnull(RCS.RateChangViewed,0)=0 
		AND isnull(RCS.RateChangViewed,0)=0 then 'Pending' end as AppStatus FROM GoodReceiptDetailId PRD
		INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
		INNER JOIN SCPTnGoodReceiptNote_M PRM ON PRD.GoodReceiptNoteId = PRM.GoodReceiptNoteId
		--LEFT OUTER JOIN SCPTnApproval APR ON APR.TransactionDocumentId = PRM.TRNSCTN_ID AND ToUSer=1013
		INNER JOIN SCPTnRateSlab RCS ON RCS.GoodReceiptDetailId = PRD.GoodReceiptDetailId
		INNER JOIN SCPStUser_M ON PRM.CreatedBy = SCPStUser_M.UserId 
		where ISNULL(PRM.IsReject,0)!=1 AND PRM.IsActive=1 AND RCS.RateChangViewed = 0 
		AND (@UserId IN(SELECT ToUSer FROM SCPTnApproval WHERE TransactionDocumentId=PRM.GoodReceiptNoteId) 
		OR ((SELECT EmployeeGroupId FROM SCPStUser_M WHERE UserId=@UserId)=2 AND PRM.CreatedBy=@UserId))
	)TMP ORDER BY CreatedDate DESC
   --Select SCPStUser_M.UserName as FromUser,SCPTnApproval.TransactionDocumentId,SCPTnApproval.TransactionDocumentId,SCPTnApproval.CreatedDate,SCPTnApproval.FormCode,
   --case when SCPTnApproval.IsApproved=1 AND SCPTnApproval.IsRejectED=0 then 'IsApproved' when SCPTnApproval.IsApproved=0 AND 
   --SCPTnApproval.IsRejectED=1 then 'Rejected' When SCPTnApproval.IsApproved=0 AND SCPTnApproval.IsRejectED=0 then 'Pending' 
   --end as AppStatus from SCPTnApproval INNER JOIN SCPStUser_M ON SCPTnApproval.FromUser = SCPStUser_M.UserId where ToUSer=@UserId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnApproval_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSentPendingApprovals]
@UserId as int
AS
BEGIN
    Select SCPStUser_M.UserName as ToUSer,SCPTnApproval.TransactionDocumentId,SCPTnApproval.TransactionDocumentId,SCPTnApproval.CreatedDate,SCPTnApproval.FormCode,
	case When isnull(SCPTnApproval.IsApproved,0)=0 AND isnull(SCPTnApproval.IsRejectED,0)=0 then 'Pending' end as AppStatus from SCPTnApproval 
	INNER JOIN SCPStUser_M ON SCPTnApproval.ToUSer = SCPStUser_M.UserId where FromUser=@UserId and SCPTnApproval.IsApproved=0 AND SCPTnApproval.IsRejectED=0
	ORDER BY SCPTnApproval.CreatedDate DESC

	--Select SCPStUser_M.UserName as ToUSer,SCPTnApproval.TransactionDocumentId,SCPTnApproval.TransactionDocumentId,SCPTnApproval.CreatedDate,SCPTnApproval.FormCode,
	--case when SCPTnApproval.IsApproved=1 AND SCPTnApproval.IsRejectED=0 then 'IsApproved' when SCPTnApproval.IsApproved=0 AND
	--SCPTnApproval.IsRejectED=1 then 'Rejected' When SCPTnApproval.IsApproved=0 AND SCPTnApproval.IsRejectED=0 then 'Pending' 
	--end as AppStatus from SCPTnApproval INNER JOIN SCPStUser_M ON SCPTnApproval.ToUSer = SCPStUser_M.UserId where FromUser=@UserId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnApproval_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserDesignation]
@DocumentType AS VARCHAR(50)
AS
BEGIN
	 SELECT Designation FROM SCPStApproval WHERE DocumentType=@DocumentType
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnApproval_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[Sp_SCPGetRateSlabItem]
@TransactionId AS INT

AS BEGIN

--SELECT PRD.ItemCode,ItemName,ItemRate AS TRD_PRICE,SalePrice,DiscountType,
--CASE WHEN DiscountType=1 AND DiscountValue!=0 THEN DiscountValue/RecievedQty 
--WHEN DiscountType=2 AND DiscountValue!=0 THEN DiscountValue ELSE 0 END DiscountValue,
--CASE WHEN DiscountType=1 AND DiscountValue!=0 THEN ItemRate-(DiscountValue/RecievedQty) 
--WHEN DiscountType=2 AND DiscountValue!=0 THEN ItemRate-((DiscountValue*ItemRate)/100)
--ELSE ItemRate END AS ItemRate FROM SCPTnPharmacyIssuance_D PRD
--INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
--INNER JOIN SCPTnRateSlab CCC ON CCC.GoodReceiptDetailId = PRD.TRNSCTN_ID
--WHERE PRD.TRNSCTN_ID=@TransactionId

SELECT PRD.ItemCode,ItemName,CAST(0 AS money) AS TRD_PRICE,SalePrice,0 DiscountType,
CAST(0 AS money) DiscountValue,ItemRate FROM SCPTnGoodReceiptNote_D PRD
INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
INNER JOIN SCPTnRateSlab CCC ON CCC.GoodReceiptDetailId = PRD.GoodReceiptDetailId
WHERE PRD.GoodReceiptDetailId=@TransactionId

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnApproval_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetApprovalMatrix]

@DocID as varchar(50)
AS

BEGIN

 select a.ToUSer,a.COMMENT,b.UserName,a.ApprovalId,
 CASE WHEN (a.IsApproved = 1 AND a.IsRejectED = 0)  THEN 'IsApproved'  
 WHEN (a.IsApproved = 0 AND a.IsRejectED = 1)  THEN 'Rejected' 
 WHEN (a.IsApproved = 0 AND A.IsRejectED = 0) THEN 'Pending' end as [Status]
 FROM SCPTnApproval as a
inner join SCPStUser_M as b on b.UserId=a.ToUSer
 where a.TransactionDocumentId=@DocID
 order by a.ApprovalId asc 
END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAPR002_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStApproval_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDesignationAndLimit]
@DocType as varchar(50),
@ItemClassfctn as int
AS
BEGIN
	select Designation,Limit from SCPStApproval where ClassificationId=@ItemClassfctn and DocumentType=@DocType and IsActive=1
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStApproval_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetApprovalMatrixLevel]
@DocType as varchar(50),
@ItemClassfctn as int,
@POAmount as money
AS
BEGIN
	
	--select Designation,Limit,coalesce(LEAD(Limit) over (order by ApprovalLevelId), 10000000000) as Limit_TO
	 --from SCPStApproval where ClassificationId=@ItemClassfctn and DocumentType=@DocType

	 select Designation,coalesce(Lag(Limit) over (order by ApprovalLevelId), 0) as Limit_FRM,Limit
     from SCPStApproval where DocumentType=@DocType and ClassificationId=@ItemClassfctn AND Limit<=(select Top 1 Limit 
     from SCPStApproval where DocumentType=@DocType and ClassificationId=@ItemClassfctn and Limit>=@POAmount) and IsActive=1;

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStApproval_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetToApprovalMatrix]
@TransactionId as varchar(50)
AS
BEGIN
	--SELECT TOP 1 (select SCPStUser_M.UserName from SCPTnApproval INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.FromUser 
 --   where TransactionDocumentId=@TransactionId and IsApproved!=1 and IsRejectED=0) as FromUser_NM,
 --   SCPStUser_M.UserName,SCPStUser_M.ADAccount from SCPTnApproval INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.ToUSer where 
 --   TransactionDocumentId=@TransactionId and IsApproved!=1 and IsRejectED=0

	
  SELECT TOP 1 (select Distinct SCPStUser_M.UserName from SCPTnApproval INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.FromUser 
  where TransactionDocumentId=@TransactionId and IsApproved=0 and IsRejectED=0) as FromUser_NM,(select Distinct SCPStUser_M.ADAccount
  from SCPTnApproval INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.FromUser where TransactionDocumentId=@TransactionId and 
  IsApproved!=1 and IsRejectED=0) as FromUser_ACC,SCPStUser_M.UserName,SCPStUser_M.ADAccount from SCPTnApproval INNER JOIN 
  SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.ToUSer where TransactionDocumentId=@TransactionId and IsApproved=0 and IsRejectED=0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStApproval_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFromApprovalUser]
@TransactionId as varchar(50)
AS
BEGIN
	  SELECT Distinct SCPTnApproval.FromUser,SCPStUser_M.UserName,SCPStUser_M.ADAccount from SCPTnApproval INNER JOIN 
     SCPStUser_M ON SCPStUser_M.UserId=SCPTnApproval.FromUser where TransactionDocumentId=@TransactionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPBonusQtyItemRecDetails]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptBonusQtyItemRecDetails]
@FromDate varchar(50),
@ToDate varchar(50),
@SupId  int
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT ID,ItemName, PP,BonusQtyQuantity,(PP*BonusQtyQuantity)AS AMOUNT FROM (
	SELECT SCPTnGoodReceiptNote_D.ItemCode AS ID,SCPStItem_M.ItemName AS ItemName,MAX(SCPTnGoodReceiptNote_D.ItemRate) AS PP, 
	SUM(SCPTnGoodReceiptNote_D.BonusQty) AS BonusQtyQuantity FROM SCPTnGoodReceiptNote_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode
    INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId=SCPTnGoodReceiptNote_M.GoodReceiptNoteId
	WHERE SCPTnGoodReceiptNote_M.SupplierId= @SupId 
	AND cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date)
	BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date) 
	GROUP BY SCPTnGoodReceiptNote_D.ItemCode,SCPStItem_M.ItemName
	 )X
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPBonusQtyItemsRecSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptBonusQtyItemsRecSummary]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

   	 SELECT SUPNAME, SUM(BonusQtyQuantity) AS NOOFITEMS, SUM(AMOUNT)AS TOTAL_Amount FROM (
	SELECT SUPNAME, ID,ItemName, PP,BonusQtyQuantity,(PP*BonusQtyQuantity)AS AMOUNT FROM (
	SELECT  SCPStSupplier.SupplierLongName AS SUPNAME, SCPTnGoodReceiptNote_D.ItemCode AS ID,SCPStItem_M.ItemName AS ItemName,
	MAX(SCPTnGoodReceiptNote_D.ItemRate) AS PP, SUM(SCPTnGoodReceiptNote_D.BonusQty) AS BonusQtyQuantity FROM SCPTnGoodReceiptNote_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode
    INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId=SCPTnGoodReceiptNote_M.GoodReceiptNoteId
	INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId
	 WHERE cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date)
	BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date)
	 GROUP BY SCPTnGoodReceiptNote_D.ItemCode,SCPStItem_M.ItemName, SCPStSupplier.SupplierLongName 
	 )X
	 )Y GROUP BY SUPNAME 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPBreakageItems]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptBreakageItems]
@FromDate AS VARCHAR(50),
 @ToDate AS VARCHAR(50),
 @WraehouseId as Int
AS
BEGIN

SELECT CAST(M.ItemDiscardDate AS datetime) AS DATE_TIME,ItemName,DosageName, 
StrengthId, BatchNo, DiscardQuantity, D.ItemCode,CAST(ClassName AS varchar) AS ClassName, UserName FROM SCPTnItemDiscard_D D 
INNER JOIN SCPTnItemDiscard_M M ON D.ItemDiscardId = M.ItemDiscardId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = D.ItemCode
INNER JOIN SCPStDosage DSG ON DSG.DosageId = ITM.DosageFormId 
INNER JOIN SCPStStrengthId ST ON ST.StrengthIdId = ITM.StrengthId
INNER JOIN SCPStClassification CLS ON CLS.ClassId = ITM.ClassId
INNER JOIN SCPStUser_M USR ON USR.UserId= D.CreatedBy
WHERE DIscardType = 2 AND CAST(M.ItemDiscardDate as date) 
BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
AND WraehouseId=@WraehouseId ORDER BY CAST(M.ItemDiscardDate AS datetime) DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCategorizedItemPercentage]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoManualFreezHoldItemPrcntg]

AS BEGIN

SELECT CAST(ROUND((CAST(MSS_AUTO_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' MSS_AUTO_PAR,
CAST(ROUND((CAST(MSS_MANUAL_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' MSS_MANUAL_PAR,
CAST(ROUND((CAST(POS_AUTO_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' POS_AUTO_PAR,
CAST(ROUND((CAST(POS_MANUAL_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' POS_MANUAL_PAR,
CAST(ROUND((CAST(FreezItem AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' FreezItem,
CAST(ROUND((CAST(OnHold AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' OnHold  FROM
(
	SELECT COUNT(ItemCode) TTL_ITEM,COUNT(MSS_AUTO_PAR) MSS_AUTO_PAR,COUNT(MSS_MANUAL_PAR) MSS_MANUAL_PAR,
	COUNT(POS_AUTO_PAR) POS_AUTO_PAR,COUNT(POS_MANUAL_PAR) POS_MANUAL_PAR,
	COUNT(FreezItem) FreezItem,COUNT(OnHold) OnHold FROM
	(
		SELECT CC.ItemCode,CASE WHEN PLM.ParLevelType='A' THEN PLM.ParLevelType END AS MSS_AUTO_PAR,
		CASE WHEN PLM.ParLevelType='M' THEN PLM.ParLevelType END AS MSS_MANUAL_PAR,
		CASE WHEN PLS.ParLevelType='A' THEN PLS.ParLevelType END AS POS_AUTO_PAR,
		CASE WHEN PLS.ParLevelType='M' THEN PLS.ParLevelType END AS POS_MANUAL_PAR,
		NULLIF(CC.FreezItem,0) FreezItem,NULLIF(CC.OnHold,0) OnHold FROM SCPStItem_M CC
		INNER JOIN SCPStParLevelAssignment_M PLM ON PLM.ItemCode = CC.ItemCode 
		AND PLM.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=10) 
		INNER JOIN SCPStParLevelAssignment_M PLS ON PLS.ItemCode = CC.ItemCode 
		AND PLS.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=3) AND CC.IsActive=1
	)TMP
)TMPP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCategorizedItemPercentage_Dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoManualFreezHoldItemPrcntgForDashboard]
 -- =============================================
-- Author:		<Author,MOIZ_HUSSAIN>
-- Create date: <Create Date, 9/16/2019 10:12:22 AM,>
-- Description:	<Description,,>
-- =============================================
AS BEGIN

SELECT CAST(ROUND((CAST(MSS_AUTO_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' MSS_AUTO_PAR,
CAST(ROUND((CAST(MSS_MANUAL_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' MSS_MANUAL_PAR,
CAST(ROUND((CAST(MSS_UNMARK AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' MSS_UNMARK,
CAST(ROUND((CAST(POS_AUTO_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' POS_AUTO_PAR,
CAST(ROUND((CAST(POS_MANUAL_PAR AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' POS_MANUAL_PAR,
CAST(ROUND((CAST(POS_UNMARK AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' POS_UNMARK,
CAST(ROUND((CAST(FreezItem AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' FreezItem,
CAST(ROUND((CAST(OnHold AS FLOAT)*100)/CAST(TTL_ITEM AS FLOAT),1) AS VARCHAR(50))+' %' OnHold  FROM
(
	SELECT COUNT(ItemCode) TTL_ITEM,COUNT(MSS_AUTO_PAR) MSS_AUTO_PAR,COUNT(MSS_MANUAL_PAR) MSS_MANUAL_PAR,
	COUNT(MSS_UNMARK) MSS_UNMARK,COUNT(POS_UNMARK) POS_UNMARK,
	COUNT(POS_AUTO_PAR) POS_AUTO_PAR,COUNT(POS_MANUAL_PAR) POS_MANUAL_PAR,
	COUNT(FreezItem) FreezItem,COUNT(OnHold) OnHold FROM
	(
		SELECT CC.ItemCode,CASE WHEN PLM.ParLevelType='A' THEN PLM.ParLevelType END AS MSS_AUTO_PAR,
		CASE WHEN PLM.ParLevelType='M' THEN PLM.ParLevelType END AS MSS_MANUAL_PAR,
		CASE WHEN PLM.ParLevelType='M' AND MedicalNeedItem!=1 THEN PLM.ParLevelType END AS MSS_UNMARK,
		CASE WHEN PLS.ParLevelType='A' THEN PLS.ParLevelType END AS POS_AUTO_PAR,
		CASE WHEN PLS.ParLevelType='M' THEN PLS.ParLevelType END AS POS_MANUAL_PAR,
		CASE WHEN PLS.ParLevelType='M' AND MedicalNeedItem!=1 THEN PLS.ParLevelType END AS POS_UNMARK,
		NULLIF(CC.FreezItem,0) FreezItem,NULLIF(CC.OnHold,0) OnHold FROM SCPStItem_M CC
		INNER JOIN SCPStParLevelAssignment_M PLM ON PLM.ItemCode = CC.ItemCode 
		AND PLM.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=10) 
		INNER JOIN SCPStParLevelAssignment_M PLS ON PLS.ItemCode = CC.ItemCode 
		AND PLS.ParLevelAssignmentId=(SELECT MAX(CRM.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=CC.ItemCode AND WraehouseId=3) AND CC.IsActive=1 AND FormularyId!=0
	)TMP
)TMPP

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPClassWiseProfit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetClassWiseProfit]

AS BEGIN

--SELECT CAST(SUM(CASE WHEN TMPPP.ClassId=1 THEN ROUND((SALE-COGS)*100/SALE,1) END) AS VARCHAR(50)) +' %' AS Medicnes,
--CAST(SUM(CASE WHEN TMPPP.ClassId=2 THEN ROUND((SALE-COGS)*100/SALE,1) END) AS VARCHAR(50)) +' %' AS Surgical  FROM

SELECT ClassName,SUM(ROUND((SALE-COGS)*100/SALE,1)) AS VALUE FROM
(
SELECT ClassId,SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
(
	SELECT ClassId,TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC,
	ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT FROM
	(
	    SELECT CC.ItemCode,cc.ClassId,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
		ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND 
		EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS REFUND,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.SaleRefundId = RD.SaleRefundId
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.SaleRefundDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND 
		EOMONTH(dateadd(m, -1,GETDATE()))  AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode AND CAST(PD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.SaleId = PD.SaleId AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY cc.ClassId,CC.ItemCode,CC.ItemName
	)TMP
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.ItemCode = TMP.ItemCode AND CAST(PRD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
	LEFT OUTER JOIN SCPTnGoodReceiptNote_M PRM ON PRD.GoodReceiptNoteId = PRM.GoodReceiptNoteId 
		AND PRM.IsActive=1 AND PRM.IsApproved=1
	GROUP BY ClassId,TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
)TMPP 
GROUP BY ClassId
)TMPPP  INNER JOIN SCPStClassification CLS ON CLS.ClassId = TMPPP.ClassId
GROUP BY ClassName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCriticalItemsIntimation]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPCriticalItemIntimation]
AS
BEGIN
  SELECT TTL_ITEM,CRITICAL_ITEM,CRITICAL_ITEM*100/TTL_ITEM AS PRCNTG FROM
  (
    SELECT (SELECT COUNT(ItemCode) FROM SCPStItem_M WHERE IsActive=1) AS TTL_ITEM,COUNT(ItemCode) AS CRITICAL_ITEM FROM 
    (
     SELECT SCPStItem_M.ItemCode,SUM(CurrentStock) AS CurrentStock,NewLevel FROM SCPStItem_M
     INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode 
	 AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT TOP 1 CPM.ParLevelAssignmentId 
     FROM SCPStParLevelAssignment_M CPM WHERE CPM.ItemCode=SCPStItem_M.ItemCode ORDER BY CPM.CreatedDate DESC)
     INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_M.ParLevelAssignmentId = SCPStParLevelAssignment_D.ParLevelAssignmentId AND ParLevelId=13 
     INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode
     WHERE CurrentStock<NewLevel GROUP BY SCPStItem_M.ItemCode,NewLevel 
    )TMP
  )TMPO
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Sp_SCPGetCategory]
 
  @ID AS bigint
 

AS
BEGIN

 SET NOCOUNT ON;

select a.CategoryId,a.CategoryName,a.IsActive,b.SubClassName,a.SubClassId  from SCPStCategory as a 
inner join SCPStSubClassification as b on a.SubClassId=a.SubClassId

where b.SubClassId=@ID

END








GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryList]
AS
BEGIN
	select a.CategoryId,a.CategoryName from SCPStCategory as a
     where IsActive=1  order by CategoryName 
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCategory_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryListBySbClass]
@SbClassId as int
AS
BEGIN
	select a.CategoryId,a.CategoryName from SCPStCategory as a
     where IsActive=1 and SubClassId=@SbClassId order by a.CategoryName
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCategory_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassSbClassByItemType] 
@ItemTypeId as int	
AS
BEGIN

SELECT SB_CLS.SubClassId,SB_CLS.SubClassName FROM SCPStClassification  CLS 
INNER JOIN SCPStSubClassification SB_CLS ON CLS.ClassId = SB_CLS.ClassId
WHERE CLS.ItemTypeId = @ItemTypeId AND SB_CLS.IsActive = 1 order by SB_CLS.SubClassName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryForSearch]
	@SubClassId as int,
	@Cat_NAME as varchar(50)
AS
BEGIN

     SELECT  C.CategoryId, C.CategoryName, b.SubClassName,b.SubClassId ,C.IsActive
     FROM  SCPStCategory C INNER JOIN SCPStSubClassification as b ON  C.SubClassId = b.SubClassId
	 WHERE C.SubClassId=@SubClassId 
	 --and C.CategoryName LIKE '%'+@Cat_NAME+'%'
	 ORDER BY CategoryId DESC
	 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryBySbClass]
 
  @ID AS bigint
 

AS
BEGIN

 SET NOCOUNT ON;

select a.CategoryId,a.CategoryName,a.IsActive,b.SubClassName,a.SubClassId  from SCPStCategory as a 
inner join SCPStSubClassification as b on a.SubClassId=b.SubClassId

where b.SubClassId=@ID

ORDER BY A.CategoryId Desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbCategoryListByCategory]
@CategoryId as int
AS
BEGIN
	 select SubCategoryId,SubCategoryName from SCPStSubCategory where IsActive=1 and CategoryId=@CategoryId order by SubCategoryName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubCategory_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCategoryListByItemType]
	@ItemTypeId as int	
AS
BEGIN
	
	SELECT  CAT.CategoryId, CategoryName  FROM SCPStClassification CLS
	 INNER JOIN SCPStSubClassification SB_CLS ON CLS.ClassId = SB_CLS.ClassId
	INNER JOIN SCPStCategory CAT  ON SB_CLS.SubClassId = CAT.SubClassId WHERE CLS.ItemTypeId = @ItemTypeId
	order by CategoryName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetSubCategoryForSearch]
 
 @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SubCategoryId,a.SubCategoryName,a.IsActive,b.CategoryName  from SCPStSubCategory as a 
inner join SCPStCategory b on a.CategoryId=b.CategoryId
where a.CategoryId=@ID and a.SubCategoryName LIKE '%'+@Search+'%' 
ORDER BY a.SubCategoryId Desc

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStClassification_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetClassByItemTypeForSearch]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.ClassId,a.ClassName,a.IsActive,b.ItemTypeId,b.ItemTypeName  from SCPStClassification as a inner join SCPStItemType as b on a.ItemTypeId=b.ItemTypeId
where b.ItemTypeId=@ID and a.ClassName LIKE '%'+@Search+'%'
ORDER BY A.ClassId Desc

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStClassification_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassList]
AS
BEGIN
	select a.ClassId,a.ClassName from SCPStClassification as a
     where IsActive=1 order by a.ClassName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStClassification_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetClassListByItemType]
@ItemTypeId as int
AS
BEGIN
	select a.ClassId,a.ClassName from SCPStClassification as a
     where IsActive=1 and ItemTypeId=@ItemTypeId order by a.ClassName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStClassification_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetClassForSearch]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.ClassId,a.ClassName,a.IsActive,b.ItemTypeId,b.ItemTypeName  from SCPStClassification as a 
inner join SCPStItemType as b on a.ItemTypeId=b.ItemTypeId
where a.ClassId=@ID and a.ClassName LIKE '%'+@Search+'%' 

END






GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubClassification_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassList]
AS
BEGIN
	 select SubClassId,SubClassName from SCPStSubClassification where IsActive=1 order by SubClassName
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubClassification_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassListByClass]
@ClassID as int
AS
BEGIN
	 select SubClassId,SubClassName from SCPStSubClassification where IsActive=1
	 and ClassId=@ClassID order by SubClassName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSubClassification_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSbClassByClassForSearch]
 
 @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SubClassId,a.SubClassName,a.IsActive,b.ClassName  from SCPStSubClassification as a inner join SCPStClassification b on a.ClassId=b.ClassId
where a.ClassId=@ID and a.SubClassName LIKE '%'+@Search+'%' 
ORDER BY a.SubClassId DESC

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStGeneric_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGenericList]

AS
BEGIN
	 select GenericId,GenericName from SCPStGeneric where IsActive=1 order by GenericName
 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStGeneric_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE  [dbo].[Sp_SCPGetGenericBySbCategory]
 @SubCateId as int
AS
BEGIN
	SET NOCOUNT ON;
SELECT GenericId, GenericName, IsActive FROM SCPStGeneric WHERE SubCategoryId = @SubCateId order by GenericId Desc
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStGeneric_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGenericBySbCategoryForSearch]
 

 @Search as varchar(50),
 @SubCateId as int

AS
BEGIN

 SET NOCOUNT ON;

select a.GenericName,a.GenericId,a.IsActive, a.SubCategoryId  from SCPStGeneric as a
where a.GenericName LIKE '%'+@Search+'%'and a.SubCategoryId= @SubCateId order by a.GenericId desc

END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStStrengthId_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStrengthIdList]
AS
BEGIN
	select StrengthIdId,StrengthIdName from SCPStStrengthId where IsActive=1 order by StrengthIdName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStStrengthId_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetStrengthIdForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.StrengthIdId,a.StrengthIdName,a.IsActive  from SCPStStrengthId as a
where a.StrengthIdName LIKE '%'+@Search+'%' 
ORDER BY StrengthIdId DESC 

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDosage_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDosageList]

AS
BEGIN
	 select DosageId,DosageName from SCPStDosage where IsActive=1 order by DosageName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDosage_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDosageForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.DosageId,a.DosageName,a.IsActive  from SCPStDosage as a
where a.DosageName LIKE '%'+@Search+'%' 
ORDER BY A.DosageId DESC 

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSigna_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSignaList]
AS
BEGIN
  select SignaId,SignaName from SCPStSigna where IsActive=1 order by SignaName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSigna_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSignaForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.SignaId,a.SignaName,a.SignaQuantity,a.SignaLabel,a.IsActive  from SCPStSigna as a
where a.SignaName LIKE '%'+@Search+'%' 
ORDER BY A.SignaId DESC 

END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRouteOfAdministration_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetRouteOfAdministrationList]
AS
BEGIN
	select RouteOfAdministrationId,RouteOfAdministrationTitle from SCPStRouteOfAdministration where IsActive=1 order by RouteOfAdministrationTitle
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRouteOfAdministration_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetSignaDetailList]
AS
BEGIN
SELECT SignaQuantity,SignaName,SignaId
FROM SCPStSigna C where IsActive=1
order by SignaName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRouteOfAdministration_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetRouteOfAdministrationForSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.RouteOfAdministrationId,a.RouteOfAdministrationTitle,a.IsActive  from SCPStRouteOfAdministration as a
where a.RouteOfAdministrationTitle LIKE '%'+@Search+'%' 
order by a.RouteOfAdministrationId Desc
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItem]
@ItemCode as varchar(50)
AS
BEGIN
	SELECT Isnull(SCPStItem_M.ItemName,0) as ItemName,Isnull(SCPStItem_M.MedicalNeedItem,0) as MedicalNeedItem, 
	Isnull(SCPStItem_M.ExpiryCategoryId,0) as ExpiryCategoryId,Isnull(SCPStItem_M.ItemTypeId,0) as ItemTypeId, Isnull(SCPStItem_M.ClassId,0) as ClassId, 
    Isnull(SCPStItem_M.SubClassId,0) as SubClassId,Isnull(SCPStItem_M.CategoryId,0) as CategoryId, Isnull(SCPStItem_M.SubCategoryId,0) as SubCategoryId, 
	Isnull(SCPStItem_M.GenericId,0) as GenericId,Isnull(SCPStItem_M.DosageFormId,0) as DosageFormId, Isnull(SCPStItem_M.FormularyId,0) as FormularyId, 
	SCPStFormulary.FormularyName,Isnull(SCPStItem_M.PackingQuantity,0) as PackingQuantity, Isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,Isnull(SCPStItem_M.ItemUnit,0) as ItemUnit, 
	Isnull(SCPStItem_M.ManufacturerId,0) as ManufacturerId, Isnull(SCPStItem_M.RouteOfAdministrationId,0) as RouteOfAdministrationId, Isnull(SCPStItem_M.SignaId,0) as SignaId,
	Isnull(SCPStItem_M.StrengthId,0) as StrengthId, Isnull(SCPStItem_M.Pneumonics,0) as Pneumonics,Isnull(SCPStRate.SalePrice,0) as SalePrice,
	Isnull( SCPStRate.CostPrice,0) as CostPrice, Isnull(SCPStRate.TradePrice,0) as TradePrice, Isnull(SCPStRate.Discount,0) as Discount,
	CASE WHEN SCPStRate.FromDate IS NULL THEN CONVERT(VARCHAR(30),GETDATE(),121) ELSE CONVERT(VARCHAR(30), SCPStRate.FromDate, 121) END AS FromDate,
	CASE WHEN SCPStRate.ToDate IS NULL THEN CONVERT(VARCHAR(30),DATEADD(YEAR,3,GETDATE()),121) ELSE CONVERT(VARCHAR(30), SCPStRate.ToDate, 121) END AS ToDate,
	SCPStItem_M.IsActive FROM SCPStItem_M 
	LEFT OUTER JOIN SCPStFormulary ON SCPStFormulary.FormularyId=SCPStItem_M.FormularyId
	LEFT OUTER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode
    and SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) between 
	FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)	where SCPStItem_M.ItemCode=@ItemCode
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemVendors]
@itemId as varchar(50)
AS
BEGIN
	SELECT SupplierId, DefaultVendor, IsActive
FROM SCPStItem_D_Supplier where ItemCode=@itemId 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsByWraehouseNameSbClass]

@subClassId as int,
@WraehouseId as int

AS
BEGIN

	--SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice, SCPTnStock_D.ItemBalance
	--FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
	--SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	--where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	--INNER JOIN SCPTnStock_D ON SCPStItem_M.ItemCode = SCPTnStock_D.ItemCode where SCPStItem_M.SubClassId=@subClassId
	--and SCPTnStock_D.WraehouseId=@WraehouseId order by SCPStItem_M.ItemCode

	Declare @ItemType as int 
    Set @ItemType = (select ItemTypeId from SCPStWraehouse where WraehouseId=@WraehouseId)

if(@ItemType = 1)
    
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice,ISnull(( SELECT TOP 1 STOCK.CurrentStock FROM 
	SCPTnStock_M STOCK WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1 ORDER 
	BY STOCK.StockId DESC),0) as ItemBalance FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode
	AND SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) 
	between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode) Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
	 WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.SubClassId=@subClassId and SCPStItem_M.IsActive=1 order by SCPStItem_M.ItemCode

ELSE if(@ItemType = 2)
 
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStRate.TradePrice,ISnull((SELECT Sum(STOCK.CurrentStock) as CurrentStock 
	FROM SCPTnStock_M STOCK WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1),0) as 
	ItemBalance FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode AND SCPStRate.ItemRateId=(select 
	isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and 
	SCPStRate.ItemCode=SCPStItem_M.ItemCode) Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId 
	and SCPStItem_M.SubClassId=@subClassId and SCPStItem_M.IsActive=1 order by SCPStItem_M.ItemCode

	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPStockTackingByWraehouseNameSbClass]
@ParentTrnsctnId as varchar(50),
@subClassId as int,
@WraehouseId as int

AS
BEGIN

	SELECT SCPTnStockTaking_D.ItemCode, SCPStItem_M.ItemName, SCPTnStockTaking_D.ItemRate, SCPTnStockTaking_D.CurrentStock, SCPTnStockTaking_D.PhysicalStock, 
    SCPTnStockTaking_D.ShortQty, SCPTnStockTaking_D.ExcessQty, SCPTnStockTaking_D.ShortAmount,  SCPTnStockTaking_D.ExcessAmount
    FROM SCPTnStockTaking_D INNER JOIN SCPStItem_D_Shelf ON SCPTnStockTaking_D.ItemCode = SCPStItem_D_Shelf.ItemCode INNER JOIN
    SCPStItem_M ON SCPTnStockTaking_D.ItemCode = SCPStItem_M.ItemCode INNER JOIN SCPTnStockTaking_M ON SCPTnStockTaking_D.StockTakingId = SCPTnStockTaking_M.StockTakingId 
	where SCPTnStockTaking_M.StockTakingId=@ParentTrnsctnId and SCPTnStockTaking_M.WraehouseId=@WraehouseId and SCPStItem_M.SubClassId=@subClassId
	and SCPStItem_M.IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAutoDemandItems] 
@WraehouseId as int
AS
BEGIN
	--SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,SUM(MinLevel) AS MinLevel,
	--SUM(MaxLevel) AS MaxLevel,(SUM(MaxLevel)-ItemBalance) as DemandQty FROM
 --  (
	--SELECT SCPStItem_M.ItemCode,ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,isnull(sum(c.CurrentStock),0) as ItemBalance,
	--CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
	--CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
	--INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
	--LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=SCPStItem_M.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
	--INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId =SCPStItem_D_WraehouseName.WraehouseId
	--INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
	--AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode and SCPStItem_M.IsActive=1
	--AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
	--GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStItem_M.ItemPackingQuantity,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
	--)TMP 
	--GROUP BY ItemCode,ItemName,ItemPackingQuantity,ItemBalance HAVING SUM(MinLevel)!=0 AND ItemBalance< SUM(MinLevel)
	--	ORDER BY ItemName


  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,MinLevel,MaxLevel,DemandQty AS DemandQty_BFR_PCK,
  CASE WHEN DemandQty<=ItemPackingQuantity THEN CAST(ItemPackingQuantity as int) ELSE 
  CAST(((ROUND(CAST(DemandQty AS decimal)/CAST(ItemPackingQuantity AS decimal),0))*ItemPackingQuantity) as int) END AS DemandQty FROM
      (
	  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,SUM(MinLevel) AS MinLevel,
		SUM(MaxLevel) AS MaxLevel,(SUM(MaxLevel)-ItemBalance) as DemandQty FROM
	   (
			SELECT SCPStItem_M.ItemCode,ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,isnull(sum(c.CurrentStock),0) as ItemBalance,
			CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
			CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
			INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
			LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=SCPStItem_M.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
			INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
			INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
			AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode and SCPStItem_M.IsActive=1
			AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
			WHERE  ItemPackingQuantity IS NOT NULL
			GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStItem_M.ItemPackingQuantity,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
		)TMP 
	GROUP BY ItemCode,ItemName,ItemPackingQuantity,ItemBalance HAVING SUM(MinLevel)!=0 AND ItemBalance<= SUM(MinLevel)
	)TMPP where DemandQty>0 ORDER BY ItemName

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D6]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManualDemandItem] 
@WraehouseId as int,
@ItemId as varchar(50)
AS
BEGIN
 SELECT ItemCode,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CurrentStock FROM
(
select p.ItemCode ,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,
isnull(SUM(c.CurrentStock),0) AS CurrentStock FROM SCPStItem_M P
INNER JOIN SCPStItem_D_WraehouseName ON P.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=P.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = P.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive=1) 
WHERE P.ItemCode=@ItemId and p.IsActive=1 GROUP BY p.ItemCode,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
)TMP GROUP BY ItemCode,CurrentStock  

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D7]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPCheckItemGenericFormulary] 
@Exist as bit,
@GenericId as bigint,
@FORMU_ID as bigint
AS
BEGIN
	IF EXISTS (SELECT a.GenericId,a.FormularyId FROM SCPStItem_M a WHERE a.GenericId=@GenericId AND a.FormularyId=@FORMU_ID)
set @Exist=1 else set @Exist=0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_D8]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetAutoDemandItemsForHoliday] 
 @WraehouseId as int 
AS
Begin

-- DECLARE @holiday as date, @date_tomorrow as date
 	
	-- SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,MinLevel,MaxLevel,DemandQty AS DemandQty_BFR_PCK,
 -- CASE WHEN DemandQty<=ItemPackingQuantity THEN CAST(ItemPackingQuantity as int) ELSE 
 -- CAST(((ROUND(CAST(DemandQty AS decimal)/CAST(ItemPackingQuantity AS decimal),0))*ItemPackingQuantity) as int) END AS DemandQty, CAST(1 AS INT) AS HOLIDAYCHECK FROM
 --     (
	--  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,SUM(MinLevel) AS MinLevel,
	--	SUM(MaxLevel) AS MaxLevel,(SUM(MaxLevel)-ItemBalance) as DemandQty FROM
	--   (
	--		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,isnull(sum(c.CurrentStock),0) as ItemBalance,
	--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
	--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
	--		INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
	--		LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=SCPStItem_M.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
	--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
	--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode and SCPStItem_M.IsActive=1
	--		AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
	--		WHERE  ItemPackingQuantity IS NOT NULL
	--		GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStItem_M.ItemPackingQuantity,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
	--	)TMP 
	--GROUP BY ItemCode,ItemName,ItemPackingQuantity,ItemBalance HAVING SUM(MinLevel)!=0 AND ItemBalance<= SUM(MinLevel)
	--)TMPP where DemandQty>0 ORDER BY ItemName;

	
	if(((select top 1 convert(date,HolidayDate) from SCPStHoliday WHERE IsActive = 1 order by CreatedDate desc) = (select convert(date,getdate()+1))) 
	OR ((SELECT DATEPART(DW, GETDATE()+1))=1))
		BEGIN
		--WORKING QUERY

		SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,MinLevel,MaxLevel,DemandQty AS DemandQty_BFR_PCK,
	  CASE WHEN DemandQty<=ItemPackingQuantity THEN CAST(ItemPackingQuantity as int) ELSE 
	  CAST(((ROUND(CAST(DemandQty AS decimal)/CAST(ItemPackingQuantity AS decimal),0))*ItemPackingQuantity) as int) END AS DemandQty , CAST(2 AS INT)  AS HOLIDAYCHECK FROM
	      (
		  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,SUM(MinLevel) AS MinLevel,
			SUM(MaxLevel) AS MaxLevel,(SUM(MaxLevel)-ItemBalance) as DemandQty FROM
		   (
				SELECT SCPStItem_M.ItemCode,ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,isnull(sum(c.CurrentStock),0) as ItemBalance,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
				LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=SCPStItem_M.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode and SCPStItem_M.IsActive=1
				AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
				WHERE  ItemPackingQuantity IS NOT NULL
				GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStItem_M.ItemPackingQuantity,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
			)TMP 
		GROUP BY ItemCode,ItemName,ItemPackingQuantity,ItemBalance HAVING SUM(MinLevel)!=0 AND ItemBalance<(SUM(MinLevel)+CAST(SUM(MinLevel) AS FLOAT)/2)
		)TMPP where DemandQty>0 ORDER BY ItemName;
		--
		END
		else

	BEGIN
	  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,MinLevel,MaxLevel,DemandQty AS DemandQty_BFR_PCK,
	  CASE WHEN DemandQty<=ItemPackingQuantity THEN CAST(ItemPackingQuantity as int) ELSE 
	  CAST(((ROUND(CAST(DemandQty AS decimal)/CAST(ItemPackingQuantity AS decimal),0))*ItemPackingQuantity) as int) END AS DemandQty, CAST(1 AS INT) AS HOLIDAYCHECK FROM
	      (
		  SELECT ItemCode,ItemName,ItemPackingQuantity,ItemBalance,SUM(MinLevel) AS MinLevel,
			SUM(MaxLevel) AS MaxLevel,(SUM(MaxLevel)-ItemBalance) as DemandQty FROM
		   (
				SELECT SCPStItem_M.ItemCode,ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,isnull(sum(c.CurrentStock),0) as ItemBalance,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
				LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=SCPStItem_M.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode and SCPStItem_M.IsActive=1
				AND CC.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
				WHERE  ItemPackingQuantity IS NOT NULL
				GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStItem_M.ItemPackingQuantity,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
			)TMP 
		GROUP BY ItemCode,ItemName,ItemPackingQuantity,ItemBalance HAVING SUM(MinLevel)!=0 AND ItemBalance<= SUM(MinLevel)
		)TMPP where DemandQty>0 ORDER BY ItemName;

	END
End
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateItemCode]
AS
BEGIN
	SELECT CAST(((SELECT TOP 1 ItemCode FROM SCPStItem_M ORDER BY ItemCode DESC)+1) AS varchar(50)) AS ItemCode
	--SELECT '9'+RIGHT('0000000'+CAST(COUNT(ItemCode)+1 AS VARCHAR(7)),7) AS ItemCode
 --   FROM SCPStItem_M 
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemList]

AS
BEGIN
	select ItemCode,ItemName from SCPStItem_M where IsActive=1 order by ItemName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPneumonicsListbyType]

AS
BEGIN
	select ItemCode,Pneumonics from SCPStItem_M where IsActive=1 and ItemTypeId=2 order by Pneumonics 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemListByWraehouseName] 
@WraehouseId as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	order by SCPStItem_M.ItemName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemPneumonicsByWraehouseNameForSearch] 
@WraehouseId as int,
@SearchID as varchar(50)
AS
BEGIN
     
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.Pneumonics+' || '+SCPStItem_M.ItemName as Pneumonics FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName	ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND CONVERT(date, getdate()) BETWEEN FromDate and ToDate
	where SCPStItem_M.IsActive=1 AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_M.Pneumonics LIKE ''+@SearchID+'%' 
	OR SCPStItem_M.ItemName LIKE ''+@SearchID+'%' 
    

	--SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.Pneumonics FROM SCPStItem_M INNER JOIN SCPStItem_D_WraehouseName 
	--ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	--order by SCPStItem_M.Pneumonics
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemClass]
@ItemId as varchar(50)
AS
BEGIN
	 select ClassId from SCPStItem_M where ItemCode=@ItemId and IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemListByType]
@ItemTypeId int
AS
BEGIN

	SET NOCOUNT ON;
		select ItemCode, ItemName from SCPStItem_M
     where IsActive=1 and ItemTypeId=@ItemTypeId order by ItemName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L6]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByWraehouseNameForSearch]
@WraehouseId as int,
@SearchID as varchar(50)
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M INNER JOIN SCPStItem_D_WraehouseName 
	ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_M.IsActive=1
	AND SCPStItem_M.ItemName LIKE '%'+@SearchID+'%' order by SCPStItem_M.ItemName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L7]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRatesbyTypeManufacturer]
@ItemTypeId  AS INT,
@ManufacturerId AS INT
AS
BEGIN
     SELECT SCPStItem_M.ItemCode,ItemName,TradePrice,CostPrice,SalePrice,Discount,FORMAT(FromDate,'dd-MM-yyyy') AS FromDate,
	 FORMAT(ToDate,'dd-MM-yyyy') AS ToDate FROM SCPStItem_M 
	 INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode  AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 WHERE ManufacturerId=@ManufacturerId AND ItemTypeId=@ItemTypeId and SCPStItem_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L8]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRatesbyTypeSupplier]
@ItemTypeId AS INT,
@SupplierId AS INT
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode,ItemName,TradePrice,CostPrice,SalePrice,Discount,FORMAT(FromDate,'dd-MM-yyyy') AS FromDate,
	 FORMAT(ToDate,'dd-MM-yyyy') AS ToDate FROM SCPStItem_M 
	 INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 INNER JOIN SCPStItem_D_Supplier ON SCPStItem_D_Supplier.ItemCode = SCPStItem_M.ItemCode WHERE SupplierId=@SupplierId AND ItemTypeId=@ItemTypeId
	 and SCPStItem_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_L9]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemRate]
@ItemCode AS VARCHAR(50)
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode,ItemName,ISNULL(TradePrice,0) TradePrice,ISNULL(CostPrice,0) CostPrice,ISNULL(SalePrice,0) SalePrice,
	 ISNULL(Discount,0) Discount,ISNULL(FORMAT(FromDate,'dd-MM-yyyy'),'01-01-0001') AS FromDate,
	 ISNULL(FORMAT(ToDate,'dd-MM-yyyy'),'01-01-0001') AS ToDate FROM SCPStItem_M 
	 LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND SCPStRate.ItemRateId=(SELECT ISNULL(Max(CRP_D.ItemRateId),0) 
	 FROM SCPStRate CRP_D WHERE CONVERT(date, GETDATE()) BETWEEN FromDate AND ToDate AND CRP_D.ItemCode = SCPStItem_M.ItemCode)
	 WHERE SCPStItem_M.ItemCode=@ItemCode and SCPStItem_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_R2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPredictedParLevel]
@AVG_DAYS AS INT,
@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;
		 --Select ItemCode,ItemName,SALES,MONTHLY_AVERAGE,DAILY_AVERAGE,CRNT_MinLevel,CRNT_MaxLevel,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,
		 -- CONVERT(varchar(50),MinLevel)+'%' AS AVG_MinLevel,CONVERT(varchar(50),MaxLevel)+'%' AS AVG_MaxLevel,(CASE WHEN MinLevel>=50 AND MaxLevel<50
		 -- THEN 'Slow Moving' WHEN MinLevel>=20 AND MinLevel<50 THEN 'Dead' WHEN MaxLevel>=50 THEN 'Fast Moving' ELSE 'None' END) as Status From 
   --       (
			--Select ItemCode, ItemName,SALES,MONTHLY_AVERAGE,DAILY_AVERAGE,CRNT_MinLevel,CRNT_MaxLevel,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,AVG_MIN,AVG_MAX,
			--(CASE WHEN MIN_PRDCTD_PAR_LVL=0 THEN 0 ELSE (AVG_MIN*100)/MIN_PRDCTD_PAR_LVL END) AS MinLevel,
			--(CASE WHEN MAX_PRDCTD_PAR_LVL=0 THEN 0 ELSE (AVG_MIN*100)/MAX_PRDCTD_PAR_LVL END) AS MaxLevel 
			--  FROM 
			--  (
			--	select itm.ItemCode, ItemName,ISNULL(PrLvl.MinLevel,0) AS CRNT_MinLevel,ISNULL(PrLvl.MaxLevel,0) AS CRNT_MaxLevel,sum(sales.Quantity) AS SALES,
			--	sum(sales.Quantity)/@Month AS MONTHLY_AVERAGE,(sum(sales.Quantity)/@Month)/30 AS DAILY_AVERAGE,((sum(sales.Quantity)/@Month)/30)*2 AS MIN_PRDCTD_PAR_LVL,
			--	((sum(sales.Quantity)/3)/30)*6 AS MAX_PRDCTD_PAR_LVL,isnull((((sum(sales.Quantity)/3)/30)*100)/MinLevel,0) AS AVG_MIN,isnull((((sum(sales.Quantity)/3)/30)*100)/PrLvl.MinLevel,0)
			--	AS AVG_MAX from SCPStItem_M itm INNER JOIN SCPTnSale_D sales ON itm.ItemCode = sales.ItemCode INNER JOIN SCPStParLevelAssignment_D PrLvl ON PrLvl.ItemCode = itm.ItemCode 
			--	AND PARENT_TRNSCTN_ID=(select isnull(Max(TRNSCTN_ID),0)	FROM SCPStParLevelAssignment_M WHERE CONVERT(date, getdate()) between FromDate and ToDate 
			--	and WraehouseId=3) WHERE sales.CreatedDate BETWEEN DATEADD(MONTH, -@Month, GETDATE()) AND GETDATE()	GROUP BY itm.ItemCode, ItemName,MinLevel,MaxLevel
		 --     )as TMP
		 --)TMP	
	declare @WraehouseName INT =  @WraehouseId
	declare @DAYS INT = @AVG_DAYS

declare @MIN_DAYS AS MONEY=(SELECT ParLevelDays FROM SCPStAutoParLevel_M WHERE WraehouseId=@WraehouseName AND ParLevelId=14)
declare @MAX_DAYS AS MONEY=(SELECT ParLevelDays FROM SCPStAutoParLevel_M WHERE WraehouseId=@WraehouseName AND ParLevelId=16)

IF(@WraehouseName= 3)
	BEGIN

	SELECT VendorChart,ItemCode,ItemName,CostPrice,SALES,DAILY_AVERAGE,
	CASE WHEN MIN_PRDCTD_PAR_LVL<= 0 THEN 1 ELSE MIN_PRDCTD_PAR_LVL END AS MIN_PRDCTD_PAR_LVL,
	CASE WHEN MAX_PRDCTD_PAR_LVL<= 0 THEN 1 ELSE MAX_PRDCTD_PAR_LVL END AS MAX_PRDCTD_PAR_LVL,
	CASE WHEN MEAN_LVL<= 0 THEN 1 ELSE MEAN_LVL END AS MEAN_LVL,ITM_Status,DIFF
	FROM
	(
		SELECT VendorChart,ItemCode,ItemName,CostPrice,SALES,DAILY_AVERAGE,CAST(MIN_PRDCTD_PAR_LVL AS INT) AS MIN_PRDCTD_PAR_LVL,
		CAST(MAX_PRDCTD_PAR_LVL AS bigint) AS MAX_PRDCTD_PAR_LVL,
		CAST(ROUND((MIN_PRDCTD_PAR_LVL+MAX_PRDCTD_PAR_LVL)/2,0) AS INT) AS MEAN_LVL,ITM_Status,DIFF FROM
		(
			SELECT VendorChart,ItemCode AS ItemCode,ItemName,AvgPerDay AS OLD_AVG,CostPrice,SOLD_QTY AS SALES,DAILY_AVERAGE,
			DAILY_AVERAGE*@MIN_DAYS AS MIN_PRDCTD_PAR_LVL,DAILY_AVERAGE*@MAX_DAYS AS MAX_PRDCTD_PAR_LVL,cast(DIFF as varchar(50))+'%' AS DIFF,
			CT.ItemConsumptionIdTypeName AS ITM_Status FROM	
			(
				SELECT VendorChart,ItemCode,ItemName,ISNULL(CostPrice,0) AS CostPrice,SOLD_QTY,
				CASE WHEN AvgPerDay=0 AND DAILY_AVERAGE=0 THEN 0 WHEN AvgPerDay=0 THEN DAILY_AVERAGE*100
				ELSE ROUND(DAILY_AVERAGE*100/AvgPerDay,0) END AS DIFF,AvgPerDay,DAILY_AVERAGE,MinLevel,MaxLevel FROM
				(
					SELECT ItemCode,ItemName,AvgPerDay,SOLD_QTY,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,
					CAST(ROUND((CAST(ISNULL(SOLD_QTY,0) AS FLOAT)/CAST(@DAYS AS FLOAT)),0) AS INT) AS DAILY_AVERAGE FROM
					(
						SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(CAST(Quantity AS bigint)),0) AS SOLD_QTY,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				     	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
						AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(DAY, -@DAYS, GETDATE()) AND GETDATE()
						INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseName
						INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
						AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
						AND CC.WraehouseId=@WraehouseName AND CC.IsActive=1)
							WHERE SCPStItem_M.IsActive=1 AND DATEDIFF(DAY,SCPStItem_M.CreatedDate,GETDATE())>=@DAYS
				       AND ISNULL(SCPStItem_M.MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
						GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
					)TMP
					 GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY
				)TMPP 
				INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = ItemCode 
				INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
				INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
				LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	            FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=ItemCode)
				GROUP BY VendorChart,ItemCode,ItemName,CostPrice,AvgPerDay,SOLD_QTY,DAILY_AVERAGE,MinLevel,MaxLevel
			)TMPPP,SCPStStockConsumptionType CT WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo
		)TMPPPP
	)TMPPPP order by VendorChart,ItemName
	END

ELSE

	BEGIN

	SELECT VendorChart,ItemCode,ItemName,CostPrice,SALES,DAILY_AVERAGE,MIN_PRDCTD_PAR_LVL,MAX_PRDCTD_PAR_LVL,
	CAST(ROUND((MIN_PRDCTD_PAR_LVL+MAX_PRDCTD_PAR_LVL)/2,0) AS INT) AS MEAN_LVL,ITM_Status,DIFF	FROM
	(
		SELECT VendorChart,ItemCode,ItemName,CostPrice,SALES,CAST(ROUND(DAILY_AVERAGE,0) AS INT) AS DAILY_AVERAGE,ITM_Status,DIFF,
		CAST(CASE WHEN MIN_PRDCTD_PAR_LVL > 0 AND MIN_PRDCTD_PAR_LVL< 1 THEN 1 ELSE MIN_PRDCTD_PAR_LVL END AS INT) AS MIN_PRDCTD_PAR_LVL,
		CAST(CASE WHEN MAX_PRDCTD_PAR_LVL > 0 AND MAX_PRDCTD_PAR_LVL< 2 THEN 2 ELSE MAX_PRDCTD_PAR_LVL END AS bigint) AS MAX_PRDCTD_PAR_LVL
		 FROM
		(
			SELECT VendorChart,ItemCode AS ItemCode,ItemName,AvgPerDay AS OLD_AVG,CostPrice,SOLD_QTY AS SALES,DAILY_AVERAGE,
			DAILY_AVERAGE*@MIN_DAYS*TotalSupplyDays AS MIN_PRDCTD_PAR_LVL,DAILY_AVERAGE*@MAX_DAYS*TotalSupplyDays AS MAX_PRDCTD_PAR_LVL,
			cast(DIFF as varchar(50))+'%' AS DIFF,CT.ItemConsumptionIdTypeName AS ITM_Status FROM	
			(
				SELECT VendorChart,TMPP.ItemCode,ItemName,ISNULL(CostPrice,0) AS CostPrice,SOLD_QTY,TotalSupplyDays,
				CASE WHEN AvgPerDay=0 AND DAILY_AVERAGE=0 THEN 0 WHEN AvgPerDay=0 THEN DAILY_AVERAGE*100
				ELSE ROUND(DAILY_AVERAGE*100/AvgPerDay,0) END AS DIFF,AvgPerDay,DAILY_AVERAGE,MinLevel,MaxLevel FROM
				(
					SELECT ItemCode,ItemName,AvgPerDay,SOLD_QTY,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,
					CAST(ISNULL(SOLD_QTY,0) AS FLOAT)/CAST(@DAYS AS FLOAT) AS DAILY_AVERAGE FROM
					(
						SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(CAST(Quantity AS bigint)),0) AS SOLD_QTY,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
						CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
						LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
						AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(DAY, -@DAYS, GETDATE()) AND GETDATE()
					    --LEFT OUTER JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode
					    --AND CAST(SCPTnPharmacyIssuance_D.CreatedDate AS DATE) BETWEEN DATEADD(DAY, -@DAYS, GETDATE()) AND GETDATE()
						INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseName
						INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
						AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
						AND CC.WraehouseId=@WraehouseName AND CC.IsActive=1)
						WHERE SCPStItem_M.IsActive=1 AND DATEDIFF(DAY,SCPStItem_M.CreatedDate,GETDATE())>=@DAYS
				       AND ISNULL(SCPStItem_M.MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
						GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel,ItemPackingQuantity
					)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY
				)TMPP 
				INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = TMPP.ItemCode 
				INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
				INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
				LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = TMPP.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
		        FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=TMPP.ItemCode)
			    GROUP BY VendorChart,TMPP.ItemCode,ItemName,CostPrice,AvgPerDay,SOLD_QTY,DAILY_AVERAGE,MinLevel,MaxLevel,TotalSupplyDays
			)TMPPP,SCPStStockConsumptionType CT WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo
		)TMPPPP 
	)TMPPPP order by VendorChart,ItemName
	END

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemForSearch]
@SearchID as varchar(50)

AS
BEGIN
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStItemType.ItemTypeName, isnull(SCPStDosage.DosageName,'') as DosageName,
	isnull(SCPStManufactutrer.ManufacturerName,'') as ManufacturerName FROM SCPStItem_M INNER JOIN SCPStItemType ON 
	SCPStItem_M.ItemTypeId = SCPStItemType.ItemTypeId LEFT OUTER JOIN SCPStDosage ON SCPStItem_M.DosageFormId = SCPStDosage.DosageId 
	LEFT OUTER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId where SCPStItem_M.ItemName 
	like '%'+@SearchID+'%' OR SCPStItem_M.ItemCode like '%'+@SearchID+'%' order by SCPStItem_M.ItemCode desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP010_S1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByTypeForSearch]
@SearchID as varchar(50),
@ItemType as int
AS
BEGIN
	 SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPStItemType.ItemTypeName, isnull(SCPStDosage.DosageName,'') as DosageName,
	isnull(SCPStManufactutrer.ManufacturerName,'') as ManufacturerName FROM SCPStItem_M 
	INNER JOIN SCPStItemType ON SCPStItem_M.ItemTypeId = SCPStItemType.ItemTypeId AND SCPStItem_M.ItemTypeId=@ItemType
	LEFT OUTER JOIN SCPStDosage ON SCPStItem_M.DosageFormId = SCPStDosage.DosageId 
	LEFT OUTER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId where
	SCPStItem_M.ItemName like '%'+@SearchID+'%' OR SCPStItem_M.ItemCode like '%'+@SearchID+'%' order by SCPStItem_M.ItemCode desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStMeasuringUnit_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnit]
@UnitId as int
AS
BEGIN
      select UnitName,IsActive from SCPStMeasuringUnit where UnitId=@UnitId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStMeasuringUnit_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnitList]
	
AS
BEGIN
	  select UnitId,UnitName from SCPStMeasuringUnit where IsActive=1 order by UnitName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStMeasuringUnit_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMeasuringUnitForSearch]
	
	@UnitName as varchar(50)
AS
BEGIN
	 SELECT UnitId,UnitName,IsActive
     FROM SCPStMeasuringUnit C WHERE UnitName LIKE '%'+@UnitName+'%' 
	 ORDER BY UnitId desc
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDose_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDose]
@DoseId as int
AS
BEGIN
      select DoseName,IsActive from SCPStDose where DoseId=@DoseId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDose_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDoseForSearch]
	
	@DoseName as varchar(50)
AS
BEGIN
	 SELECT DoseId,DoseName,IsActive
     FROM SCPStDose C WHERE DoseName LIKE '%'+@DoseName+'%' 
	 ORDER BY DoseId DESC 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShelf_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelf]
@ShelfId as int
AS
BEGIN
      select RackId,ShelfName,SCPStShelf.IsActive,SCPStRack.WraehouseId  from SCPStShelf
	  INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
	   where RackId.ShelfId=@ShelfId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShelf_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfByRack] 
@ID as int
AS
BEGIN
	 select ShelfId,ShelfName from SCPStShelf where IsActive=1 and RackId=@ID order by ShelfName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShelf_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfList]
	
AS
BEGIN
	select ShelfId,ShelfName from SCPStShelf where IsActive=1 order by ShelfName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShelf_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfForSearch]
	
	@ShelfName as varchar(50)
AS
BEGIN
	SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStRack.RackName , SCPStWraehouse.WraehouseName,SCPStShelf.IsActive
    FROM SCPStShelf INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
	 INNER JOIN SCPStWraehouse ON SCPStRack.WraehouseId = SCPStWraehouse.WraehouseId 
	WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' OR SCPStShelf.ShelfId LIKE '%'+@ShelfName+'%'
	OR SCPStShelf.RackId LIKE '%'+@ShelfName+'%' OR SCPStWraehouse.WraehouseName LIKE '%'+@ShelfName+'%'
	--SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStWraehouse.WraehouseName, SCPStShelf.IsActive
 --   FROM SCPStShelf INNER JOIN SCPStWraehouse ON SCPStShelf.WraehouseId = SCPStWraehouse.WraehouseId 
	--WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' OR SCPStShelf.ShelfId LIKE '%'+@ShelfName+'%'
	--OR SCPStWraehouse.WraehouseName LIKE '%'+@ShelfName+'%'
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShelf_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetShelfByRackForSearch]
	
	@ShelfName as varchar(50),@ParentShlfId bigint
AS
BEGIN
	SELECT SCPStShelf.ShelfId, SCPStShelf.ShelfName, SCPStWraehouse.WraehouseName, SCPStShelf.IsActive,SCPStRack.RackName
    FROM SCPStShelf  INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
	INNER JOIN SCPStWraehouse ON SCPStRack.WraehouseId = SCPStWraehouse.WraehouseId 
	WHERE SCPStShelf.ShelfName LIKE '%'+@ShelfName+'%' 
	and SCPStShelf.RackId=@ParentShlfId 
	ORDER BY SCPStShelf.ShelfId Desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRack_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRack]
@ParentShlfId as int
AS
BEGIN
      select WraehouseId,RackName,IsActive from SCPStRack
	  where RackId=@ParentShlfId
	  ORDER BY RackId DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRack_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRackByWraehouseName]

@W_ID as bigint
AS
BEGIN
	
	SET NOCOUNT ON;
	SELECT * FROM SCPStRack WHERE WraehouseId = @W_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRack_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetRackForSearch]
	
	@ShelfParentName as varchar(50)
	,@W_ID bigint
AS
BEGIN


	SELECT RackId, RackName,
	SCPStRack.IsActive, SCPStWraehouse.WraehouseName
    FROM SCPStRack
	INNER JOIN SCPStWraehouse ON SCPStRack.WraehouseId = SCPStWraehouse.WraehouseId 
	WHERE SCPStRack.RackName LIKE '%'+@ShelfParentName+'%' and SCPStRack.WraehouseId=@W_ID 
	 AND SCPStRack.WraehouseId=SCPStWraehouse.WraehouseId
	ORDER BY RackId DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemParLevel]
@ItemId as varchar(50),
@WraehouseName as int
AS
BEGIN
	
	SET NOCOUNT ON;

  --  SELECT cc.ParLevelId,ParLevelName, CC.CreatedDate, isnull(CC.Currentlevel,0) as Currentlevel,
  --isnull(CC.NewLevel,0) as LVL FROM SCPStParLevelAssignment_D CC INNER JOIN SCPStParLevel PL ON PL.ParLevelId = CC.ParLevelId
  -- where CC.ItemCode = @ItemId and cc.WraehouseId = @WraehouseName
  --AND CC.CreatedDate=(SELECT MAX(SCPStParLevelAssignment_D.CreatedDate) FROM SCPStParLevelAssignment_D WHERE SCPStParLevelAssignment_D.ItemCode=CC.ItemCode 
  --AND SCPStParLevelAssignment_D.ParLevelId=CC.ParLevelId) GROUP BY  CC.CreatedDate,CC.Currentlevel,CC.NewLevel,PL.ParLevelName,cc.ParLevelId
  --order by cc.ParLevelId

-- SELECT PD.ParLevelId,ParLevelName, PM.TRNSCTN_DATE,
-- isnull(PD.Currentlevel,0) as Currentlevel,
--isnull(PD.NewLevel,0) as LVL FROM SCPStParLevelAssignment_M PM INNER JOIN SCPStParLevelAssignment_D PD 
--ON PD.PARENT_TRNSCTNID = PM.TRNSCTN_ID
--INNER JOIN SCPStParLevel PL ON PL.ParLevelId = PD.ParLevelId
--   where PM.ItemCode = '90000665' and PM.WraehouseId = 3
--  AND Pm.TRNSCTN_DATE=(SELECT MAX(SCPStParLevelAssignment_M.TRNSCTN_DATE) FROM SCPStParLevelAssignment_D INNER JOIN SCPStParLevelAssignment_M 
--  ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId  WHERE SCPStParLevelAssignment_M.ItemCode=PM.ItemCode 
--   AND SCPStParLevelAssignment_M.WraehouseId = PM.WraehouseId
--  AND SCPStParLevelAssignment_D.ParLevelId=PD.ParLevelId) 
--  GROUP BY  PD.Currentlevel,PD.NewLevel,PL.ParLevelName,PD.ParLevelId,PM.TRNSCTN_DATE
--  ORDER BY ParLevelId
 SELECT PL.ParLevelId,ParLevelName,
 isnull(PD.Currentlevel,0) as Currentlevel,
isnull(PD.NewLevel,0) as LVL FROM SCPStParLevelAssignment_M PM INNER JOIN SCPStParLevelAssignment_D PD 
ON PD.ParLevelAssignmentId = PM.ParLevelAssignmentId
RIGHT OUTER JOIN SCPStParLevel PL ON PL.ParLevelId = PD.ParLevelId
AND PM.ItemCode = @ItemId and PM.WraehouseId = @WraehouseName
AND PM.ParLevelAssignmentId =(SELECT MAX(SCPStParLevelAssignment_M.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M  INNER JOIN SCPStParLevelAssignment_D
ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId  WHERE SCPStParLevelAssignment_M.ItemCode=PM.ItemCode 
AND SCPStParLevelAssignment_M.WraehouseId = PM.WraehouseId
AND SCPStParLevelAssignment_D.ParLevelId=PD.ParLevelId) 
WHERE PL.IsActive = 1
GROUP BY  PD.Currentlevel,PD.NewLevel,PL.ParLevelName,PL.ParLevelId,SerialNo
ORDER BY SerialNo
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetParLevelTransaction_M]
@Trnsctn_ID as varchar(50)

AS
BEGIN
	 SELECT ParLevelAssignmentId, ParLevelAssignmentDate,  WraehouseId, ItemCode , AvgPerDay
     FROM  SCPStParLevelAssignment_M where ParLevelAssignmentId= @Trnsctn_ID
	 Order by ParLevelAssignmentId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetParLevelTransaction_D]
@TransactionId as varchar(50)
AS
BEGIN
    SELECT D.ParLevelId, Currentlevel, NewLevel, ParLevelName FROM SCPStParLevelAssignment_D D
INNER JOIN SCPStParLevel ON SCPStParLevel.ParLevelId = D.ParLevelId WHERE ParLevelAssignmentId = @TransactionId
order by ParLevelId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsWraehouseNameParLevels]
@itemCode as varchar(50)
AS
BEGIN

--	declare @maxColumnCount int=0;
-- declare @Query varchar(max)='';
-- declare @DynamicColumnName nvarchar(MAX)='';

---- table type variable that store all values of column row no
-- DECLARE @TotalRows TABLE( row_count int)
-- INSERT INTO @TotalRows (row_count)
 
--	SELECT  (ROW_NUMBER() OVER(PARTITION BY SCPStParLevelAssignment_M.WraehouseId order by SCPStParLevelAssignment_M.WraehouseId Desc)) as row_no FROM SCPStParLevelAssignment_M
--	LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_D_Shelf.ItemCode AND SCPStItem_D_Shelf.WraehouseId = SCPStParLevelAssignment_M.WraehouseId
--	INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId
--	AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode
--	AND CC.WraehouseId = SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive = 1) WHERE SCPStParLevelAssignment_M.ItemCode=@itemCode

---- Get the MAX value from @TotalRows table
-- set @maxColumnCount= (select max(row_count) from @TotalRows)
 
---- loop to create Dynamic max/case and store it into local variable 
-- DECLARE @cnt INT = 1;
-- WHILE @cnt <= @maxColumnCount
-- BEGIN
--   set @DynamicColumnName= @DynamicColumnName + ', Max(case when row_no= '+cast(@cnt as varchar)+' then NewLevel end )as PAR_LVL_'+cast(@cnt as varchar)+''
--   SET @cnt = @cnt + 1;
--END;

---- Create dynamic CTE and store it into local variable @query 
--  set @Query='with CTE_tbl as
--     (
--	 SELECT SCPStParLevelAssignment_M.WraehouseId,isnull(ShelfId,0) AS ShelfId,SCPStParLevelAssignment_D.NewLevel,
--	 ROW_NUMBER() OVER(PARTITION BY SCPStParLevelAssignment_M.WraehouseId order by SCPStParLevelAssignment_M.WraehouseId Desc) as row_no FROM SCPStParLevelAssignment_M 
--	 LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_D_Shelf.ItemCode AND SCPStItem_D_Shelf.WraehouseId = SCPStParLevelAssignment_M.WraehouseId
--	 INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId
--	 AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode
--	 AND CC.WraehouseId = SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive = 1) WHERE SCPStParLevelAssignment_M.ItemCode=@itemCode
--	 )
--  select
--     WraehouseId,ShelfId
--     '+@DynamicColumnName+'
--     FROM CTE_tbl
--     group By WraehouseId,ShelfId'
---- Execute the Query
-- execute (@Query)

      SELECT WraehouseId,NewLevel,PARENT_TRNSCTNID,AvgPerDay FROM
     (
	 SELECT SCPStParLevelAssignment_M.WraehouseId,SCPStParLevelAssignment_D.ParLevelId,isnull(SCPStParLevelAssignment_D.NewLevel,0) NewLevel, 
	 isnull(SCPStParLevelAssignment_M.ParLevelAssignmentId,'') AS PARENT_TRNSCTNID,
	 isnull(SCPStParLevelAssignment_M.AvgPerDay,0) as AvgPerDay FROM SCPStParLevelAssignment_M 
     INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId
	 INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStParLevelAssignment_M.ItemCode
	 AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode
	 AND CC.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId AND CC.IsActive = 1)
	 WHERE SCPStParLevelAssignment_M.ItemCode=@itemCode 
	 UNION ALL
     SELECT SCPStItem_D_WraehouseName.WraehouseId,ParLevelId,0 AS NewLevel,'' AS PARENT_TRNSCTNID,0 AS AvgPerDay FROM SCPStParLevel,SCPStItem_D_WraehouseName
	 WHERE SCPStItem_D_WraehouseName.ItemCode =@itemCode AND  SCPStParLevel.IsActive=1 AND ParLevelId NOT IN(SELECT ParLevelId FROM SCPStParLevelAssignment_D 
	 INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
	 AND SCPStParLevelAssignment_M.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId AND SCPStParLevelAssignment_M.ItemCode=@itemCode))TMP order by WraehouseId,ParLevelId
	 

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_D5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetParLevelTransaction]
@Trnsctn_ID as varchar(50),
@Item_Id as varchar(50)

AS
BEGIN

IF(@Item_Id = '0')
	SELECT PARLVL.ParLevelAssignmentId, ParLevelAssignmentDate, ItemName, WraehouseName FROM SCPStParLevelAssignment_M PARLVL 
	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PARLVL.ItemCode and ITM.IsActive=1
	INNER JOIN SCPStWraehouse WraehouseName  ON WraehouseName.WraehouseId = PARLVL.WraehouseId
	 where PARLVL.ParLevelAssignmentId LIKE '%'+@Trnsctn_ID+'%' or ItemName LIKE '%'+@Trnsctn_ID+'%' 
	 order by PARLVL.ParLevelAssignmentId desc

IF(@Item_Id != '0')
	 SELECT PARLVL.ParLevelAssignmentId, ParLevelAssignmentDate, ItemName, WraehouseName FROM SCPStParLevelAssignment_M PARLVL 
	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PARLVL.ItemCode and ITM.IsActive=1
	INNER JOIN SCPStWraehouse WraehouseName  ON WraehouseName.WraehouseId = PARLVL.WraehouseId
	 where PARLVL.ItemCode LIKE '%'+@Item_Id+'%' AND PARLVL.ParLevelAssignmentId LIKE '%'+@Trnsctn_ID+'%' 
	  order by PARLVL.ParLevelAssignmentId desc
 -- if(@ParentTrnsctnId='0')
 -- Begin

 --  SELECT TRNSCTN_ID,ITM_CODE,ItemName,CRNT_MinLevel,CRNT_MaxLevel,MinLevel,MaxLevel FROM
 -- (
 --   SELECT isnull(CC.TRNSCTN_ID,0) as TRNSCTN_ID,isnull(SCPStItem_M.ItemCode,0) as ITM_CODE, isnull(SCPStItem_M.ItemName,0) as ItemName,
 --   isnull(CC.CRNT_MinLevel,0) as CRNT_MinLevel,  isnull(CC.CRNT_MaxLevel,0) as CRNT_MaxLevel, isnull(CC.MinLevel,0) as MinLevel, 
 --   isnull(CC.MaxLevel,0) as MaxLevel FROM  SCPStItem_M inner join SCPStItem_D_WraehouseName on SCPStItem_D_WraehouseName.ItemCode= SCPStItem_M.ItemCode and 
 --   SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId  left outer JOIN SCPStParLevelAssignment_D CC ON SCPStItem_M.ItemCode = CC.ItemCode and 
 --   cc.PARENT_TRNSCTN_ID=(select isnull(Max(TRNSCTN_ID),0) from SCPStParLevelAssignment_M where CONVERT(date, getdate()) between FromDate 
 --   and ToDate and WraehouseId=SCPStItem_D_WraehouseName.WraehouseId)  
 --  )TMP WHERE ItemName like '%'+@SearchID+'%'

 --END

 --  else

 --BEGIN

 -- SELECT TRNSCTN_ID,ITM_CODE,ItemName,CRNT_MinLevel,CRNT_MaxLevel,MinLevel,MaxLevel FROM
 -- (
 --   SELECT isnull(CC.TRNSCTN_ID,0) as TRNSCTN_ID,isnull(SCPStItem_M.ItemCode,0) as ITM_CODE, isnull(SCPStItem_M.ItemName,0) as ItemName,
 --   isnull(CC.CRNT_MinLevel,0) as CRNT_MinLevel,  isnull(CC.CRNT_MaxLevel,0) as CRNT_MaxLevel, isnull(CC.MinLevel,0) as MinLevel, 
 --   isnull(CC.MaxLevel,0) as MaxLevel FROM  SCPStItem_M inner join SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode and 
 --   SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId left outer JOIN SCPStParLevelAssignment_D CC ON SCPStItem_M.ItemCode = CC.ItemCode and 
 --   cc.PARENT_TRNSCTN_ID=@ParentTrnsctnId  
	-- )TMP where ItemName like '%'+@SearchID+'%'
 --END
 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP014_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateParLevelNo]

AS
BEGIN
	SELECT 'PL-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(ParLevelAssignmentId)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPStParLevelAssignment_M
	WHERE MONTH(ParLevelAssignmentDate) = MONTH(getdate())
    AND YEAR(ParLevelAssignmentDate) = YEAR(getdate())

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategory]
@MncftrCatId as int
AS
BEGIN
      select ManufacturerCategoryName,IsActive from SCPStManufactutrerCategory where ManufacturerCategoryId=@MncftrCatId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategoryList]
AS
BEGIN
	select ManufacturerCategoryId,ManufacturerCategoryName from SCPStManufactutrerCategory
     where IsActive=1 order by ManufacturerCategoryName
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerCategoryForSearch]
	
	@MncftrCatName as varchar(50)
AS
BEGIN
	 SELECT ManufacturerCategoryId,ManufacturerCategoryName,IsActive
     FROM SCPStManufactutrerCategory C WHERE ManufacturerCategoryName LIKE '%'+@MncftrCatName+'%' 
	 ORDER BY ManufacturerCategoryId Desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrer]
@ManufacturerId as int
AS
BEGIN
     SELECT ManufacturerName,ManufacturerCategoryId,IsActive
     FROM SCPStManufactutrer  WHERE ManufacturerId=@ManufacturerId 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerList]
AS
BEGIN
	 select ManufacturerId,ManufacturerName from SCPStManufactutrer where IsActive=1 order by ManufacturerName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStManufactutrerCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetManufactutrerForSearch]
	@ManufacturerCate_ID as int,
	@Manufacturer_NAME as varchar(50)
AS
BEGIN

     SELECT  C.ManufacturerId, C.ManufacturerName, SCPStManufactutrerCategory.ManufacturerCategoryName, C.IsActive
     FROM  SCPStManufactutrer C INNER JOIN SCPStManufactutrerCategory ON  C.ManufacturerCategoryId = SCPStManufactutrerCategory.ManufacturerCategoryId
	 WHERE C.ManufacturerCategoryId=@ManufacturerCate_ID and C.ManufacturerName LIKE '%'+@Manufacturer_NAME+'%'
	 ORDER BY C.ManufacturerName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplierCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategory]
@SupplierCatId as int
AS
BEGIN
      select SupplierCategoryName,IsActive from SCPStSupplierCategory where SupplierCategoryId=@SupplierCatId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplierCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategoryList]
AS
BEGIN
	select SupplierCategoryId,SupplierCategoryName from SCPStSupplierCategory
     where IsActive=1 order by SupplierCategoryName
 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplierCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierCategoryForSearch]
	
	@SupplierCatName as varchar(50)
AS
BEGIN
	 SELECT SupplierCategoryId,SupplierCategoryName,IsActive
     FROM SCPStSupplierCategory C WHERE SupplierCategoryName LIKE '%'+@SupplierCatName+'%' 
	 ORDER BY SupplierCategoryId Desc
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplier]
@SupplierId as int
AS
BEGIN
    SELECT SupplierCategoryId,ItemTypeId,'' SupplierShortName, SupplierLongName, FaxNo, STRegistrationNo,SaleTaxNo,AmountLimit,ContactNo1,
	ContactNo2,Address,DaysLimit,PaymentDayType,PaymentDate, PaymentDay ,PaymentDayType,OrderDayType,OrderDate,VendorChartId,
	OrderDay,OrderDayDetail,LeadTime,IsActive FROM SCPStSupplier where SupplierId=@SupplierId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierList]
AS
BEGIN
	 select a.SupplierId,a.SupplierLongName from SCPStSupplier as a
     where a.IsActive=1 order by a.SupplierLongName
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierListByType]
@ItemTypeId AS INT
AS
BEGIN
	SELECT SupplierId,SupplierLongName FROM SCPStSupplier WHERE ItemTypeId=@ItemTypeId AND IsActive=1 order by SupplierLongName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierListPendingPR]
@ItemTypeId as INT
AS
BEGIN
      SELECT DISTINCT SCPStSupplier.SupplierId,SupplierLongName FROM SCPStSupplier
      INNER JOIN SCPStItem_D_Supplier ON SCPStItem_D_Supplier.SupplierId = SCPStSupplier.SupplierId
      INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.ItemCode = SCPStItem_D_Supplier.ItemCode AND PendingQty>0
	  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPurchaseRequisition_D.ItemCode
	  INNER JOIN SCPTnPurchaseRequisition_M ON SCPTnPurchaseRequisition_M.TRANSCTN_ID = PARENT_TRANS_ID 
	  AND SCPTnPurchaseRequisition_M.IsApprove=1 AND IsReject=0
	  AND SCPStItem_M.IsActive=1
	  WHERE SCPStSupplier.ItemTypeId=@ItemTypeId AND SCPStSupplier.IsActive=1  ORDER BY SupplierLongName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierListPendingPo] 
@ItemTypeId as INT
AS
BEGIN
	  SELECT DISTINCT SCPStSupplier.SupplierId,SupplierLongName FROM SCPStSupplier
      INNER JOIN SCPStItem_D_Supplier ON SCPStItem_D_Supplier.SupplierId = SCPStSupplier.SupplierId
      INNER JOIN SCPTnPurchaseOrder_D ON SCPTnPurchaseOrder_D.ItemCode = SCPStItem_D_Supplier.ItemCode AND PendingQty>0
	  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
	  INNER JOIN SCPTnPurchaseOrder_M ON SCPTnPurchaseOrder_M.PurchaseOrderId = SCPTnPurchaseOrder_D.PurchaseOrderId 
	  AND SCPTnPurchaseOrder_M.SupplierId = SCPStSupplier.SupplierId
	  AND SCPTnPurchaseOrder_M.IsApprove=1 AND SCPStItem_M.IsActive=1
	  WHERE SCPStSupplier.ItemTypeId=@ItemTypeId AND SCPStSupplier.IsActive=1  ORDER BY SupplierLongName

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSupplier_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSupplierForSearch]
@CategoryId as int,
@VNDR_S_NAME as varchar(50)
AS
BEGIN
	SELECT  C.SupplierId, SCPStSupplierCategory.SupplierCategoryName,SCPStItemType.ItemTypeName ,C.SupplierShortName, C.SupplierLongName, C.FaxNo, C.STRegistrationNo, C.ContactNo1,
    C.ContactNo2, C.Address, C.DaysLimit
    FROM  SCPStSupplier C INNER JOIN SCPStSupplierCategory ON SCPStSupplierCategory.SupplierCategoryId = C.SupplierCategoryId
	INNER JOIN SCPStItemType ON SCPStItemType.ItemTypeId = C.ItemTypeId
    WHERE C.SupplierCategoryId=@CategoryId and (C.SupplierShortName LIKE '%'+@VNDR_S_NAME+'%' OR
	C.SupplierLongName LIKE '%'+@VNDR_S_NAME+'%')
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStConsultant_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetConsultant]
@ConsultantId as int
AS
BEGIN
     SELECT ConsultantName,QualificationId,SpecialityId,IsActive 
     FROM SCPStConsultant  WHERE ConsultantId=@ConsultantId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStConsultant_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetConsultantForSearch]
	@SpecialityId as int,
	@QualificationId as int,
	@ConsultantName as varchar(50)
AS
BEGIN
	 SELECT  C.ConsultantId, C.ConsultantName, SCPStQualification.QualificationName, SCPStSpeciality.ConsultantSpecialityName,
     C.IsActive FROM  SCPStConsultant C INNER JOIN SCPStSpeciality ON C.SpecialityId = SCPStSpeciality.ConsultantSpecialityId 
     INNER JOIN SCPStQualification ON C.QualificationId = SCPStQualification.QualificationId WHERE C.SpecialityId=@SpecialityId 
     AND C.QualificationId=@QualificationId AND C.ConsultantName LIKE '%'+@ConsultantName+'%' 
	 ORDER BY C.ConsultantName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCountry_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetCountry]
(
@COUNTRY_ID AS INT)
AS
BEGIN
SELECT C.CountryName,C.IsActive
FROM SCPStCountry C
WHERE C.CountryId=@COUNTRY_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCountry_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCountryList]
AS
BEGIN
	select CountryId,CountryName from SCPStCountry
     where IsActive=1 order by CountryName
 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCountry_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetCountryForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.CountryId,C.CountryName,C.IsActive
FROM  SCPStCountry C
WHERE C.CountryName LIKE '%'+@name+ '%' 
ORDER BY C.CountryName
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCity_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCity]
@CityId as int
AS
BEGIN
     SELECT CityName,CountryId,IsActive
     FROM SCPStCity  WHERE CityId=@CityId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCity_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCityForSearch]
	@CategoryId  as int,
	@name as varchar(50)
AS
BEGIN
SELECT C.CityId,C.CityName,C.IsActive,CS.CountryName
FROM  SCPStCity C,SCPStCountry CS
WHERE C.CityName LIKE '%'+@name+ '%' and c.CountryId=@CategoryId  AND C.CountryId=CS.CountryId
ORDER BY C.CityName
	 --SELECT C.CityId, C.CityName, SCPStCountry.CountryName, SCPStCountry.IsActive
  --   FROM SCPStCity C INNER JOIN SCPStCountry ON C.CountryId = SCPStCountry.CountryId WHERE C.CountryId=@CNTRY_ID and C.CityName LIKE '%'+@CityName+'%' 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCompany_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetCompany]
(
@CompanyId AS INT)
AS
BEGIN
SELECT C.IsActive,c.CompanyCode,c.CompanyPRF,C.CompanyName
FROM SCPStCompany C
WHERE C.CompanyId=@CompanyId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCompany_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCompanyList]

AS
BEGIN
	 select CompanyId,CompanyName from SCPStCompany where IsActive=1 order by CompanyName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStCompany_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetCompanyForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.CompanyId,C.CompanyName,c.CompanyCode,c.CompanyPRF,C.IsActive
FROM  SCPStCompany C
WHERE C.CompanyName LIKE '%'+@name+ '%' 
ORDER BY C.CompanyId Desc
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPaymentMode_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPaymentMode]
(
@CompanyId AS INT)
AS
BEGIN
SELECT c.ModeOfPaymentId,c.IsActive
FROM SCPStPaymentMode C
WHERE C.ModeOfPaymentId=@CompanyId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPaymentMode_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPaymentModeForSearch]

(@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ModeOfPaymentId,C.ModeOfPaymentId,C.IsActive
FROM  SCPStPaymentMode C
WHERE C.ModeOfPaymentId LIKE '%'+@name+ '%' 
ORDER BY C.ModeOfPaymentId desc
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPaymentTerm_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPaymentTerm]
(
@PAYMENT_ID AS INT)
AS
BEGIN
SELECT C.PaymentTermName,C.IsActive
FROM SCPStPaymentTerm C
WHERE C.PaymentTermId=@PAYMENT_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPaymentTerm_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPaymentTermList]
	
AS
BEGIN
	select PaymentTermId,PaymentTermName from SCPStPaymentTerm where IsActive=1 order by PaymentTermName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPaymentTerm_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPaymentTermForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.PaymentTermId,C.PaymentTermName,C.IsActive
FROM  SCPStPaymentTerm C
WHERE C.PaymentTermName LIKE '%'+@name+ '%' 
ORDER BY C.PaymentTermName
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShift_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetShift]
(
@SHIFT_ID AS INT)
AS
BEGIN
SELECT C.ShiftName,C.IsActive
FROM SCPStShift C
WHERE C.ShiftId=@SHIFT_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStShift_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetShiftForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ShiftId,C.ShiftName,C.IsActive
FROM  SCPStShift C
WHERE C.ShiftName LIKE '%'+@name+ '%' 
ORDER BY C.ShiftName
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFeild_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetFeild]
(
@FIELD AS INT)
AS
BEGIN
SELECT C.CConsultantFeildName,C.IsActive
FROM SCPStFeild C
WHERE C.ConsultantFeildId=@FIELD
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFeild_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetFeildList]
AS
BEGIN
SELECT C.ConsultantFeildId,C.CConsultantFeildName
FROM SCPStFeild C where C.IsActive=1 order by C.CConsultantFeildName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFeild_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetFeildForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT C.ConsultantFeildId,C.CConsultantFeildName,C.IsActive
FROM  SCPStFeild C
WHERE C.CConsultantFeildName LIKE '%'+@name+ '%' 
ORDER BY C.ConsultantFeildId Desc
END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSpeciality_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetSpeciality]
(
@SPEC AS INT)
AS
BEGIN
SELECT C.ConsultantSpecialityName,C.ConsultantFeildId,C.IsActive
FROM SCPStSpeciality C
WHERE C.ConsultantSpecialityId=@SPEC
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSpeciality_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSpecialityList]
AS
BEGIN
	select ConsultantSpecialityId,ConsultantSpecialityName from SCPStSpeciality
     where IsActive=1 order by ConsultantSpecialityName
 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStSpeciality_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetSpecialityForSearch]
(
@name VARCHAR(50),
@CategoryId bigint
)
AS
BEGIN
SELECT C.ConsultantSpecialityId,C.ConsultantSpecialityName,C.IsActive,CS.CConsultantFeildName
FROM  SCPStSpeciality C,SCPStFeild CS
WHERE C.ConsultantSpecialityName LIKE '%'+@name+ '%' and c.ConsultantFeildId=@CategoryId  AND C.ConsultantFeildId=CS.ConsultantFeildId
ORDER BY C.ConsultantSpecialityId desc
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRate_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetItemRateChange]
(
@ITEM_ID AS varchar(50))
AS
BEGIN
SELECT c.ItemRateId,c.ItemCode,c.CreatedDate,C.IsActive,C.FromDate,C.SalePrice,C.ToDate,C.TradePrice,C.CostPrice,M.ItemName,C.Discount
FROM SCPStRate C ,SCPStItem_M M
WHERE C.ItemRateId=@ITEM_ID AND C.ItemCode=M.ItemCode
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRate_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPItemTradePriceList]
@ItemCode AS VARCHAR(50)
AS
BEGIN
    SELECT ItemCode,TradePrice FROM SCPStRate WHERE 
    SCPStRate.ItemRateId=(select isnull(Max(CRP.ItemRateId),0) from SCPStRate CRP where CONVERT(date, getdate()) between 
	CRP.FromDate and CRP.ToDate and CRP.ItemCode=SCPStRate.ItemCode)
	AND SCPStRate.ItemCode=@ItemCode
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRate_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetItemRateForSearch]
(
@name VARCHAR(50)

)
AS
BEGIN
--select c.ItemRateId,C.ITM_CODE,P_M.ItemName,C.TradePrice,C.CostPrice,C.SalePrice,C.FromDate,C.ToDate,C.IsActive
--from  SCPStRate c
--INNER JOIN SCPStItem_M P_M ON P_M.ItemCode =c.ITM_CODE
--WHERE P_M.ItemName LIKE '%'+@name+ '%' 
select c.ItemRateId,C.ItemCode,P_M.ItemName,C.TradePrice,C.CostPrice,C.SalePrice,convert(date,C.FromDate)as FromDate ,convert(date,C.ToDate) as ToDate ,C.IsActive
from  SCPStRate c
INNER JOIN SCPStItem_M P_M ON P_M.ItemCode =c.ItemCode 
WHERE P_M.ItemName LIKE '%'+@name+ '%' and ItemRateId=(select max(ItemRateId)from SCPStRate where c.ItemCode=ItemCode)


END 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStRate_U]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE proc [dbo].[Sp_SCPUpdateCloseItemRate]
	(
	@from_date varchar(50),
	@code varchar(50)
	)
	as
	begin
	update SCPStRate set ToDate=DATEADD(day,-1,@from_date) where ItemCode=@code and CONVERT(date, getdate()) between FromDate and ToDate
	end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStQualification_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetQualification]
(
@QualiId AS INT)
AS
BEGIN
SELECT C.QualificationName,C.IsActive
FROM SCPStQualification C
WHERE C.QualificationId=@QualiId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStQualification_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetQualificationList]
AS
BEGIN
	select QualificationId,QualificationName from SCPStQualification
     where IsActive=1 order by QualificationName
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStQualification_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPQualificationForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT c.QualificationName ,c.QualificationId,c.IsActive
FROM  SCPStQualification c
WHERE c.QualificationName LIKE '%'+@name+ '%' 
ORDER BY c.QualificationName
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetWraehouseName]
(
@FormCode AS INT)
AS
BEGIN
SELECT C.WraehouseName,C.IsActive,ItemTypeId
FROM SCPStWraehouse C
WHERE C.WraehouseId=@FormCode
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameList]
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouse where IsActive=1  order by WraehouseId
 END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameForPos]
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouse where IsActive=1 and ItemTypeId=2 order by WraehouseId
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameByType]
@ItemTypeId as int
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouse where IsActive=1 AND ItemTypeId=@ItemTypeId  order by WraehouseId
 END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWraehouseNameForPurchase]
@ItemTypeId as int
AS
BEGIN
	select WraehouseId,WraehouseName from SCPStWraehouse where IsActive=1 AND IsAllow=1
    AND ItemTypeId=@ItemTypeId  order by WraehouseId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetWraehouseNameForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT SCPStWraehouse.WraehouseId, SCPStWraehouse.WraehouseName, SCPStItemType.ItemTypeName, SCPStWraehouse.IsActive
FROM SCPStWraehouse INNER JOIN SCPStItemType ON SCPStWraehouse.ItemTypeId = SCPStItemType.ItemTypeId

WHERE WraehouseName LIKE '%'+@name+ '%' 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStWraehouse_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetWraehouseNameByTypeForSearch]
(
@name VARCHAR(50),
@Type_id bigint
)
AS
BEGIN
SELECT SCPStWraehouse.WraehouseId, SCPStWraehouse.WraehouseName, SCPStItemType.ItemTypeName, SCPStWraehouse.IsActive
FROM SCPStWraehouse INNER JOIN SCPStItemType ON SCPStWraehouse.ItemTypeId = SCPStItemType.ItemTypeId

WHERE WraehouseName LIKE '%'+@name+ '%'  and SCPStWraehouse.ItemTypeId=@Type_id  AND SCPStWraehouse.ItemTypeId=SCPStItemType.ItemTypeId
ORDER BY SCPStWraehouse.WraehouseName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientSubCategory_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategory]
 
   @ID AS bigint,
 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

select a.PatientSubCategoryId,a.PatientSubCategoryName,a.IsActive,a.PatientCategoryId,b.PatientCategoryName  from SCPStPatientSubCategory as a inner join SCPStPatientCategory as b on a.PatientCategoryId=b.PatientCategoryId
where b.PatientCategoryId=@ID and a.PatientSubCategoryName LIKE '%'+@Search+'%'
ORDER BY a.PatientSubCategoryId desc

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientSubCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDepartmentList]
AS
BEGIN
	select DepartmentId as DPTMNT_ID ,DepartmentName  as DPTMNT from SCPStDepartment where IsActive=1 order by DepartmentName
 END 

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientSubCategory_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategoryByCategory]
@SCPPatientCatId as int
AS
BEGIN
	select PatientSubCategoryId,PatientSubCategoryName from SCPStPatientSubCategory 
	where PatientCategoryId=@SCPPatientCatId and IsActive=1 order by PatientSubCategoryName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientSubCategory_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientSubCategoryList]

AS
BEGIN
	select PatientSubCategoryId,PatientSubCategoryName from SCPStPatientSubCategory where IsActive=1 order by PatientSubCategoryName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientSubCategory_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientCategoryList]
AS
BEGIN
	select a.PatientCategoryId,a.PatientCategoryName from SCPStPatientCategory as a
     where a.IsActive=1 order by a.PatientCategoryName
 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItemType_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemType]
@TypeId as int
AS
BEGIN
      select ItemTypeName,IsActive from SCPStItemType where ItemTypeId=@TypeId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItemType_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeByWraehouseName]
@WraehouseId as int
AS
BEGIN
	  select SCPStItemType.ItemTypeId,SCPStItemType.ItemTypeName from SCPStItemType INNER JOIN SCPStWraehouse ON 
	  SCPStWraehouse.ItemTypeId=SCPStItemType.ItemTypeId where SCPStWraehouse.WraehouseId=@WraehouseId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItemType_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeList]
AS
BEGIN
	select ItemTypeId,ItemTypeName from SCPStItemType 
     where IsActive=1 order by ItemTypeName
 END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItemType_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeForRate]
@ItemTypeId AS INT
AS
BEGIN
	SELECT AlllowSale FROM SCPStItemType WHERE ItemTypeId=@ItemTypeId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItemType_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeForSearch]
	
	@ItemType as varchar(50)
AS
BEGIN
	 SELECT ItemTypeId,ItemTypeName,IsActive
     FROM SCPStItemType WHERE ItemTypeId LIKE '%'+@ItemType+'%' OR ItemTypeName LIKE '%'+@ItemType+'%' 
	 ORDER BY ItemTypeId DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormulary_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetFormulary]
(
@FormCode AS INT)
AS
BEGIN
SELECT SCPStFormulary.FormularyName, SCPStFormulary.PriorityNo,IsActive
FROM SCPStFormulary 
WHERE SCPStFormulary.FormularyId=@FormCode
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormulary_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFormularyBygeneric]
@FormularyType as int,
@GenericId as int
AS
BEGIN
	--select FormularyId,FormularyName from SCPStFormulary where IsActive=1 and FRMLRY_TYPE_ID=@FormularyType
	select FormularyId,FormularyName from SCPStFormulary where IsActive=1 
    and FormularyId NOT IN(select FormularyId from SCPStItem_M where GenericId=@GenericId)
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormulary_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFormularyList]
@FormularyType as int

AS
BEGIN
	select FormularyId,FormularyName from SCPStFormulary where IsActive=1 order by FormularyName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormulary_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC [dbo].[Sp_SCPGetFormularyForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT SCPStFormulary.FormularyId, SCPStFormulary.FormularyName, SCPStFormulary.PriorityNo, SCPStFormulary.IsActive
FROM SCPStFormulary 
WHERE FormularyName LIKE '%'+@name+ '%' 
order by SCPStFormulary.FormularyId DESC
END  

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientType_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientType]
(
@PatientTypeId AS INT)
AS
BEGIN
SELECT C.PatientTypeName,C.IsActive
FROM SCPStPatientType C
WHERE C.PatientTypeId=@PatientTypeId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientType_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPatientTypeForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT PatientTypeId,PatientTypeName,IsActive
FROM  SCPStPatientType
WHERE PatientTypeName LIKE '%'+@name+ '%' 
ORDER BY PatientTypeName
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[Sp_SCPGetPatientCategory]
(
@PatientCategoryId AS INT)
AS
BEGIN
SELECT C.PatientCategoryName,C.IsActive
FROM SCPStPatientCategory C
WHERE C.PatientCategoryId=@PatientCategoryId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPatientCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetPatientCategoryForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT PatientCategoryName,PatientCategoryId,IsActive
FROM  SCPStPatientCategory
WHERE PatientCategoryName LIKE '%'+@name+ '%' ORDER BY PatientCategoryId Desc
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDepartment_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[Sp_SCPGetDepartment]
(
@DepartmentId AS INT)
AS
BEGIN
SELECT C.DepartmentName,C.IsActive
FROM SCPStDepartment C
WHERE C.DepartmentId=@DepartmentId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDepartment_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemTypeList]
AS
BEGIN
	select a.ItemTypeName,a.ItemTypeId from SCPStItemType as a
     where IsActive=1 order by a.ItemTypeName
 END




GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDepartment_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetDepartmentForSearch]
(
@name VARCHAR(50)
)
AS
BEGIN
SELECT DepartmentName ,DepartmentId,IsActive
FROM  SCPStDepartment
WHERE DepartmentName LIKE '%'+@name+ '%' 
ORDER BY DepartmentId Desc
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItem_D_Shelf_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByWraehouseNameShelf]

@shelfId as int,
@WraehouseId as int
AS
BEGIN
 
	--SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, SCPTnStock_D.ItemBalance, SCPStRate.TradePrice
 --   FROM SCPStItem_M INNER JOIN SCPTnStock_D ON SCPStItem_M.ItemCode = SCPTnStock_D.ItemCode INNER JOIN
	--SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ITM_CODE and SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0)
	--from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ITM_CODE=SCPStItem_M.ItemCode)
	--INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode where SCPStItem_D_Shelf.ShelfId=@shelfId
	--and SCPTnStock_D.WraehouseId=@WraehouseId order by SCPStItem_M.ItemCode

	--SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, sum(isnull(SCPTnStock_D.ItemBalance,0)) as ItemBalance, 
 --   isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPTnStock_D ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode AND 
	--isnull(SCPTnStock_D.StockId,0)=(select  ISNULL(max(StockId),0) from SCPTnStock_D iv where SCPTnStock_D.ItemCode=iv.ItemCode and SCPTnStock_D.BatchNo=iv.BatchNo) 
	--INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0)
	--from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	--INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId  
	--where SCPTnStock_D.WraehouseId=@WraehouseId group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice
	
----		Declare @ItemType as int 
----    Set @ItemType = (select ItemTypeId from SCPStWraehouse where WraehouseId=@WraehouseId)

----if(@ItemType = 1)
----    SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, ISnull((SELECT TOP 1 STOCK.CurrentStock FROM SCPTnStock_M STOCK
----	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1 ORDER 
----	BY STOCK.StockId DESC),0) as ItemBalance, isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPStRate 
----	ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0) 
----	from SCPStRate where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode) 
----	Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
----	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
----    WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND ISnull(( SELECT TOP 1 STOCK.CurrentStock FROM SCPTnStock_M STOCK
----	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1 ORDER 
----	BY STOCK.StockId DESC),0)>0 group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice

----ELSE if(@ItemType = 2)
 
----	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, ISnull((SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK 
----	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1),0) as ItemBalance, 
----    isnull(SCPStRate.TradePrice,0) as TradePrice FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
----	isnull(SCPStRate.ItemRateId,0)=(select isnull(Max(ItemRateId),0) from SCPStRate where CONVERT(date, getdate()) 
----	between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
----	 Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
----	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
----	WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND
----	ISnull((SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK 
----	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.IsActive = 1),0)>0
----	group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPStRate.TradePrice 



SELECT  ItemCode,ItemName,BatchNo,ItemBalance, TradePrice FROM (
    SELECT X.ItemCode,ItemName,X.BatchNo,ItemBalance, CASE WHEN X.BatchNo = '0' THEN CostPrice
   ELSE CASE WHEN ItemRate IS NULL THEN CostPrice ELSE ItemRate END END AS TradePrice FROM (
	SELECT SCPStItem_M.ItemCode, SCPStItem_M.ItemName, STOCK.BatchNo, STOCK.CreatedDate
	, STOCK.CurrentStock as ItemBalance FROM SCPStItem_M 
	Inner join SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode AND WraehouseId =@WraehouseId
	INNER JOIN	SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode and SCPStItem_D_Shelf.ShelfId=@shelfId
	INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.IsActive = 1
    WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1 AND CurrentStock>0
	group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName, STOCK.BatchNo, STOCK.CurrentStock, STOCK.CreatedDate
	)x
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON X.ItemCode = SCPTnGoodReceiptNote_D.ItemCode AND X.BatchNo = SCPTnGoodReceiptNote_D.BatchNo
	INNER JOIN SCPStRate ON X.ItemCode = SCPStRate.ItemCode  AND SCPStRate.FromDate <= X.CreatedDate and SCPStRate.ToDate >= X.CreatedDate 
	)Y --WHERE TradePrice IS NOT NULL
	
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItem_D_Shelf_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTackingByWraehouseNameShelf] 
@ParentTrnsctnId as varchar(50),
@shelfId as int,
@WraehouseId as int
AS
BEGIN
	SELECT SCPTnStockTaking_D.ItemCode, SCPStItem_M.ItemName,SCPTnStockTaking_D.ItemRate, SCPTnStockTaking_D.CurrentStock, SCPTnStockTaking_D.PhysicalStock, 
    SCPTnStockTaking_D.ShortQty, SCPTnStockTaking_D.ExcessQty, SCPTnStockTaking_D.ShortAmount,  SCPTnStockTaking_D.ExcessAmount  FROM SCPTnStockTaking_D 
	INNER JOIN SCPStItem_D_Shelf ON SCPTnStockTaking_D.ItemCode = SCPStItem_D_Shelf.ItemCode 
	INNER JOIN  SCPStItem_M ON SCPTnStockTaking_D.ItemCode = SCPStItem_M.ItemCode and SCPStItem_M.IsActive=1
	INNER JOIN SCPTnStockTaking_M ON SCPTnStockTaking_D.StockTakingId = SCPTnStockTaking_M.StockTakingId 
	where SCPTnStockTaking_M.StockTakingId=@ParentTrnsctnId and SCPTnStockTaking_M.WraehouseId=@WraehouseId and SCPStItem_D_Shelf.ShelfId=@shelfId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItem_D_Shelf_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemByShelf]
@ShelfSetupID as int
AS
BEGIN
	SELECT ShelfId,ItemCode,WraehouseId,IsActive
    FROM SCPStItem_D_Shelf where ItemShelfMappingId = @ShelfSetupID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItem_D_Shelf_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemShelf]
@itemCode AS VARCHAR(50)
AS
BEGIN
	 --SELECT SCPStItem_D_WraehouseName.WraehouseId,isnull(ShelfId,0) AS ShelfId FROM SCPStItem_D_WraehouseName 
	 --LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_D_Shelf.ItemCode AND 
	 --SCPStItem_D_Shelf.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	  SELECT SCPStItem_D_WraehouseName.WraehouseId,isnull(SCPStItem_D_Shelf.ShelfId,0) AS ShelfId,
			isnull(SCPStShelf.RackId,0) AS RackId
 		FROM SCPStItem_D_WraehouseName 
	 LEFT OUTER JOIN SCPStItem_D_Shelf ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_D_Shelf.ItemCode AND 
	 SCPStItem_D_Shelf.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	 left outer join SCPStShelf on SCPStItem_D_Shelf.ShelfId = SCPStShelf.ShelfId
	 WHERE SCPStItem_D_WraehouseName.ItemCode=@itemCode
		 AND SCPStItem_D_Shelf.CreatedDate = (select isnull(Max(CreatedDate),0) from SCPStItem_D_Shelf RS where 
	  RS.ItemCode=SCPStItem_D_Shelf.ItemCode and rs.WraehouseId = SCPStItem_D_Shelf.WraehouseId)
     order by SCPStItem_D_WraehouseName.WraehouseId
END

GO


/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStItem_D_Shelf_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetItemShelfForSearch]
@shlef as varchar(50),
@SHLFID as int
AS
BEGIN

  SELECT SCPStItem_D_Shelf.ItemShelfMappingId, SCPStShelf.ShelfName,SCPStItem_M.ItemName ,SCPStShelf.ShelfId, SCPStItem_D_Shelf.IsActive FROM SCPStItem_M 
  INNER JOIN SCPStItem_D_Shelf ON SCPStItem_M.ItemCode = SCPStItem_D_Shelf.ItemCode 
  INNER JOIN SCPStShelf ON SCPStItem_D_Shelf.ShelfId = SCPStShelf.ShelfId 
  INNER JOIN SCPStRack ON SCPStRack.RackId = SCPStShelf.RackId
   AND  SCPStItem_D_Shelf.ShelfId =@SHLFID
  --INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId=SCPStItem_D_Shelf.WraehouseId 
  --AND SCPStItem_D_Shelf.WraehouseId=3 
  WHERE SCPStItem_M.ItemName LIKE '%'+@shlef+'%' OR SCPStShelf.ShelfName LIKE '%'+@shlef+'%' 
  --order by SCPStItem_D_Shelf.WraehouseId,SCPStItem_D_Shelf.ItemShelfMappingId, SCPStShelf.ShelfName
  ORDER BY SCPStItem_D_Shelf.ItemShelfMappingId Desc

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP040_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetkit_D]
@Trnsctn_ID as varchar(50)
AS
BEGIN
		SELECT b.ItemCode,b.Quantity,b.KitId,x.ItemName
FROM  SCPStKit_D as b 
inner join SCPStItem_M x on b.ItemCode=x.ItemCode and x.IsActive=1
where b.KitId=@Trnsctn_ID and b.IsActive=1
END
















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP040_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPGetkit_M]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.KitName,a.KitCategoryId,a.IsActive
FROM  SCPStKit_M as a 
where a.KitId=@Trnsctn_ID and a.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP040_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[Sp_SCPGeneratekitNo]

AS
BEGIN
	SELECT 'KI-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(KitId)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPStKit_M

END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP040_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetkitForSearch]
@Trnsctn_ID as varchar(50),
@KitCatId as INT
AS
BEGIN
SELECT a.KitId,a.KitName FROM SCPStKit_M as a 
where KitCategoryId=@KitCatId AND (a.KitId LIKE '%'+@Trnsctn_ID+'%' or a.KitName like '%'+@Trnsctn_ID+'%')
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStEmployee_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployee]
@EmpId as varchar(50)
AS
BEGIN
	 select EmployeeCode as EMP_ID,EmployeeName as EMP_NM from SCPStEmployee where IsActive=1 and EmployeeCode=@EmpId
END

GO


/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStEmployeeGetEmployee]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeforSearch]
 

 @Search as varchar(50)
 

AS
BEGIN

 SET NOCOUNT ON;

--select a.EMP_NM,a.EMP_ID,a.IsActive  from SCPStEmployee as a
--where a.EMP_NM LIKE '%'+@Search+'%' 
select a.EmployeeName,a.EmployeeCode,a.IsActive  from SCPStEmployee as a
where a.EmployeeName LIKE '%'+@Search+'%' 
ORDER BY EmployeeCode Desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStNamePrefix_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetNamePrefixList]

AS
BEGIN
  select NamePrefixId,NamePrefixName from SCPStNamePrefix where IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStPartner_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetPartnerForSearch]
 

 @Search as varchar
 

AS
BEGIN

 SET NOCOUNT ON;

select a.PartnerId,a.PartnerName,a.IsActive  from SCPStPartner as a
where a.PartnerName LIKE '%'+@Search+'%' ORDER BY a.PartnerName

END






GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP044_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[Sp_SCPGetParLevel]
@lvlId as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   select ParLevelName, IsActive,SerialNo from SCPStParLevel where ParLevelId = @lvlId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP044_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[Sp_SCPGetParLevelSequenceForSearch] 
@PARLVL as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

   	 SELECT ParLevelId,  ParLevelName, IsActive
     FROM SCPStParLevel C WHERE ParLevelName LIKE '%'+ @PARLVL+'%' AND IsActive=1
	 ORDER BY SerialNo 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCRP044_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE  [dbo].[Sp_SCPGetParLevelForSearch] 
@PARLVL as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

   	 SELECT ParLevelId,  ParLevelName, IsActive, SerialNo
     FROM SCPStParLevel C WHERE ParLevelName LIKE '%'+ @PARLVL+'%' 
	 ORDER BY ParLevelId Desc 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStParLevel_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetParLevelList]
AS
BEGIN

SELECT ParLevelId,ParLevelName FROM SCPStParLevel WHERE IsActive=1

END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStKitCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategory]
@KitCatId as int
AS
BEGIN
      select KitCategoryId,IsActive from SCPStKitCategory where KitCategoryIdegoryId=@KitCatId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStKitCategory_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategoryByPatientCategory]
@PtCateId as int
AS
BEGIN
	 SELECT KitCategoryIdegoryId,KitCategoryId FROM SCPStKitCategory WHERE IsActive=1 AND PatientCategoryId=@PtCateId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStKitCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetKitCategoryForSearch]
	@PtCateId as int,
	@KitCate as varchar(50)
AS
BEGIN
	 SELECT KitCategoryIdegoryId,KitCategoryId,IsActive
     FROM SCPStKitCategory WHERE  PatientCategoryId=@PtCateId AND (KitCategoryIdegoryId LIKE '%'+@KitCate+'%' OR KitCategoryId LIKE '%'+@KitCate+'%')
	 ORDER BY KitCategoryIdegoryId DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStHoliday_Edit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create proc [dbo].[Sp_SCPGetHoliday] 
(
@Id AS INT)
AS
BEGIN
SELECT C.Title, C.HolidayDate,C.IsActive 
FROM SCPStHoliday C
WHERE C.HolidayId=@Id
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStHoliday_Search]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetHolidayForSearch]
(
@title VARCHAR(50)
)
AS
BEGIN
SELECT Title ,HolidayId,HolidayDate,IsActive
FROM  SCPStHoliday
WHERE Title LIKE '%'+@title+ '%' 
ORDER BY HolidayDate
END  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStExpiryCategory_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryCategory]
@ExpiryCatId as int
AS
BEGIN
      select ExpiryCategoryT,ExpiryDurationFrom,ExpiryDurationFromType,ExpiryDurationTo,ExpiryDurationToType,
	  IntimationTime,IntimationTimeType,OffShelfTime,OffShelfTimeType,IsActive 
	  from SCPStExpiryCategory where ExpiryCategoryId=@ExpiryCatId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStExpiryCategory_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetItemExpiryCategory]
@ITEM_ID AS VARCHAR(50)
AS BEGIN
		SELECT CASE WHEN ST.TimeDurationType='Month' THEN DATEADD(MONTH,ExpiryDurationFrom,GETDATE()) 
		WHEN ST.TimeDurationType='Year' THEN DATEADD(YEAR,ExpiryDurationFrom,GETDATE()) 
		ELSE DATEADD(DAY,ExpiryDurationFrom,GETDATE()) END AS EXPR_FROM,
		CASE WHEN DT.TimeDurationType='Month' THEN DATEADD(MONTH,ExpiryDurationTo,GETDATE()) 
		WHEN DT.TimeDurationType='Year' THEN DATEADD(YEAR,ExpiryDurationTo,GETDATE()) 
		ELSE DATEADD(DAY,ExpiryDurationTo,GETDATE()) END AS EXPR_TO FROM SCPStItem_M CC
		INNER JOIN SCPStExpiryCategory EXPR ON EXPR.ExpiryCategoryId = CC.ExpiryCategoryId
		INNER JOIN SCPStTimeType ST ON ST.TimeDurationTypeId = ExpiryDurationFromType
		INNER JOIN SCPStTimeType DT ON DT.TimeDurationTypeId = ExpiryDurationToType
		WHERE ItemCode=@ITEM_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStExpiryCategory_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryCategoryForSearch]
@ExpiryCat as varchar(50)
AS
BEGIN
      SELECT ExpiryCategoryId,ExpiryCategoryT,ExpiryDurationFrom,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=ExpiryDurationFromType) AS ExpiryDurationFromType,ExpiryDurationTo,
	  (SELECT TimeDurationType FROM SCPStTimeType WHERE TimeDurationTypeId=ExpiryDurationToType) AS ExpiryDurationToType,
	  IntimationTime,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=IntimationTimeType) AS IntimationTimeType,
	  OffShelfTime,(SELECT TimeDurationType FROM SCPStTimeType 
	  WHERE TimeDurationTypeId=OffShelfTimeType) AS OffShelfTimeType,SCPStExpiryCategory.IsActive FROM SCPStExpiryCategory 
	  WHERE ExpiryCategoryT LIKE '%'+@ExpiryCat+'%' 
	  ORDER BY ExpiryCategoryT desc
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStVendorChart_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE PROC [dbo].[Sp_SCPGetVendorChart]
   AS BEGIN
  SELECT VendorChartId,VendorChart FROM SCPStVendorChart WHERE IsActive=1
  END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetAutoParLevel]
@WAREOUSE_ID AS INT
AS BEGIN
SELECT WraehouseName,ParLevelName,ParLevelDays,ParLevelApplyDays,ParLevelConsumptionDays FROM SCPStAutoParLevel_M APL
INNER JOIN SCPStWraehouse WH ON APL.WraehouseId = WH.WraehouseId
INNER JOIN SCPStParLevel LVL ON LVL.ParLevelId = APL.ParLevelId
WHERE APL.WraehouseId=@WAREOUSE_ID
END 


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetAutoParLevelCycle]
AS BEGIN

SELECT WraehouseId,NEW_START_TIME FROM
(
	SELECT ROW_NUMBER() OVER(Partition by WraehouseId ORDER BY NEW_START_TIME DESC) AS ROW_NUM,
	WraehouseId,NEW_START_TIME FROM 
	(
		SELECT DISTINCT MSTR.WraehouseId,CASE WHEN DTL.ExecutionEndTime IS NULL 
		THEN (CASE WHEN MSTR.EditedDate IS NULL THEN CAST(DATEADD(DAY,ParLevelApplyDays,MSTR.CreatedDate) AS date) 
		ELSE CAST(DATEADD(DAY,ParLevelApplyDays,MSTR.EditedDate) AS date) END)
		ELSE CAST(DATEADD(DAY,ParLevelApplyDays,ExecutionEndTime) AS date) END AS NEW_START_TIME 
		FROM SCPStAutoParLevel_M MSTR
		LEFT OUTER JOIN SCPTnAutoParLevel DTL ON MSTR.WraehouseId = DTL.WraehouseId
		WHERE MSTR.IsActive=1 --AND DTL.IsActive=1
	)TMP 
)TMPP WHERE ROW_NUM=1

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoParLevelByWraehouseName]
@WraehouseId AS INT
AS BEGIN
SELECT ParLevelId,ParLevelDays,ParLevelApplyDays,ParLevelConsumptionDays FROM SCPStAutoParLevel_M
WHERE WraehouseId=@WraehouseId AND IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetAutoParLevelItems]
@AVG_DAYS AS INT,
@WARWHOUSE_ID AS INT,
@ParLevelDays AS MONEY

AS BEGIN


IF(@WARWHOUSE_ID=3)
	BEGIN

		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN NEW_PAR_LVL<= 0 THEN 1 ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM 
		(
			SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
				CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0)*@ParLevelDays AS INT) AS NEW_PAR_LVL
				FROM SCPStItem_M CC
				LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
				AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
				WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
				 AND ISNULL(MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
				GROUP BY CC.ItemCode,ItemPackingQuantity,CC.CreatedDate
		)TMPP ORDER BY ItemCode
		END

ELSE IF(@WARWHOUSE_ID=10)
	BEGIN

	SELECT ItemCode,ItemPackingQuantity,CAST(ROUND(AVG_CNSMPTN,0) AS INT) AVG_CNSMPTN,
	CASE WHEN ITM_PAR_LVL >0 AND ITM_PAR_LVL < @ParLevelDays THEN CAST(ROUND(@ParLevelDays,0) AS INT) ELSE CAST(ROUND(ITM_PAR_LVL,0) AS INT) END AS ITM_PAR_LVL FROM 
	(
		SELECT CC.ItemCode,ItemPackingQuantity,(CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)) AVG_CNSMPTN,
			(CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT))*@ParLevelDays*TotalSupplyDays AS ITM_PAR_LVL
			FROM SCPStItem_M CC
			LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
			AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
			INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = CC.ItemCode 
			INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
			INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
			WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
			 AND ISNULL(MedicalNeedItem,0)!=1 AND ISNULL(OnHold,0)!=1 AND ISNULL(FreezItem,0)!=1 AND FormularyId!=0
			GROUP BY CC.ItemCode,ItemPackingQuantity,TotalSupplyDays --ORDER BY CC.ItemCode
		)TMPP ORDER BY ItemCode

	END


--IF(@WARWHOUSE_ID=3)
--	BEGIN

--		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN ITM_PAR_LVL<= 0 THEN 1 ELSE ITM_PAR_LVL END AS ITM_PAR_LVL FROM 
--		(
--			SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN @IS_PACK_APPLY=1 THEN 
--			CASE WHEN NEW_PAR_LVL=0 THEN 0 WHEN NEW_PAR_LVL<ItemPackingQuantity THEN ItemPackingQuantity 
--			ELSE CAST(((ROUND(CAST(NEW_PAR_LVL AS decimal)/CAST(ItemPackingQuantity  AS decimal),0))*ItemPackingQuantity) as int) END 
--			ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM
--			(
--				SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
--				CAST(ROUND((CAST(ISNULL(SUM(PHD.Quantity),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT)*@ParLevelDays AS NEW_PAR_LVL
--				FROM SCPStItem_M CC
--				LEFT OUTER JOIN SCPTnSale_D PHD ON PHD.ItemCode = CC.ItemCode 
--				AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE()
--				WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
--				AND CC.MedicalNeedItem=0 AND OnHold!=1 AND FreezItem!=1
--				GROUP BY CC.ItemCode,ItemPackingQuantity,CC.CreatedDate
--			)TMP 
--		)TMPP ORDER BY ItemCode
--		END

--ELSE IF(@WARWHOUSE_ID=10)
--	BEGIN

--		SELECT ItemCode,ItemPackingQuantity,AVG_CNSMPTN,CASE WHEN @IS_PACK_APPLY=1 THEN 
--		CASE WHEN NEW_PAR_LVL=0 THEN 0  WHEN NEW_PAR_LVL<ItemPackingQuantity THEN ItemPackingQuantity 
--		ELSE CAST(((ROUND(CAST(NEW_PAR_LVL AS decimal)/CAST(ItemPackingQuantity  AS decimal),0))*ItemPackingQuantity) as int) END 
--		ELSE NEW_PAR_LVL END AS ITM_PAR_LVL FROM
--		(
--			SELECT CC.ItemCode,ItemPackingQuantity,CAST(ROUND((CAST(ISNULL(SUM(PHD.IssueQty),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT) AVG_CNSMPTN,
--			CAST(ROUND((CAST(ISNULL(SUM(PHD.IssueQty),0) AS FLOAT)/CAST(@AVG_DAYS AS FLOAT)),0) AS INT)*@ParLevelDays*TotalSupplyDays AS NEW_PAR_LVL
--			FROM SCPStItem_M CC
--			LEFT OUTER JOIN SCPTnPharmacyIssuance_D PHD ON PHD.ItemCode = CC.ItemCode 
--			AND PHD.CreatedDate BETWEEN DATEADD(DAY,-@AVG_DAYS,GETDATE()) AND GETDATE() 
--			INNER JOIN SCPStItem_D_Supplier CD ON CD.ItemCode = CC.ItemCode 
--			INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = CD.SupplierId AND DefaultVendor=1
--			INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
--			WHERE CC.IsActive=1 AND DATEDIFF(DAY,CC.CreatedDate,GETDATE())>=@AVG_DAYS
--			AND CC.MedicalNeedItem=0 AND OnHold!=1 AND FreezItem!=1
--			GROUP BY CC.ItemCode,ItemPackingQuantity,TotalSupplyDays
--		)TMP ORDER BY ItemCode

--	END
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetFreezItems]
AS BEGIN
SELECT DISTINCT CC.ItemCode FROM SCPStItem_M CC
INNER JOIN SCPTnPurchaseOrder_D PRC ON PRC.ItemCode = CC.ItemCode AND PendingQty>0
INNER JOIN SCPTnPurchaseOrder_M PRM ON PRM.PurchaseOrderId = PurchaseOrderId
AND PRM.PurchaseOrderId = (SELECT TOP 1 PurchaseOrderId FROM SCPTnPurchaseOrder_D WHERE ItemCode=CC.ItemCode ORDER BY CreatedDate DESC)
INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = PRM.SupplierId 
INNER JOIN SCPStVendorChart CHART ON CHART.VendorChartId = SUP.VendorChartId
WHERE CC.IsActive=1 AND CC.MedicalNeedItem=0 AND DATEDIFF(DAY,PRM.PurchaseOrderDate,GETDATE())>=TotalSupplyDays
GROUP BY PurchaseOrderId,PurchaseOrderDate,DATEDIFF(DAY,PRM.PurchaseOrderDate,GETDATE()),CC.ItemCode 
HAVING SUM(CAST(PendingQty AS FLOAT))/SUM(CAST(OrderQty AS FLOAT))*100>50
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStAutoParLevel_M_L5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetAutoParLevelDateByWraehouseName]
 @WraehouseName  as int
AS BEGIN
 --DECLARE @WraehouseName  as int = 3
SELECT WraehouseId,FORMAT(NEW_START_TIME,'dd-MMM-yyyy HH:mm:ss')  AS NEXT_START_TIME,(
SELECT TOP 1 FORMAT(ExecutionEndTime,'dd-MMM-yyyy HH:mm:ss') 
FROM SCPTnAutoParLevel  WHERE WraehouseId = @WraehouseName ORDER BY ExecutionEndTime DESC) AS LAST_EXECUTED FROM (
SELECT WraehouseId,NEW_START_TIME FROM
(
	SELECT ROW_NUMBER() OVER(Partition by WraehouseId ORDER BY NEW_START_TIME DESC) AS ROW_NUM,
	WraehouseId,convert(datetime,TMP.NEW_START_TIME,120) as NEW_START_TIME FROM 
	(
		SELECT DISTINCT MSTR.WraehouseId,CASE WHEN DTL.ExecutionEndTime IS NULL 
		THEN (CASE WHEN MSTR.EditedDate IS NULL THEN CAST(DATEADD(DAY,ParLevelApplyDays,MSTR.CreatedDate) AS date) 
		ELSE CAST(DATEADD(DAY,ParLevelApplyDays,MSTR.EditedDate) AS datetime) END)
		ELSE CAST(DATEADD(DAY,ParLevelApplyDays,ExecutionEndTime) AS datetime) END AS NEW_START_TIME 
		FROM SCPStAutoParLevel_M MSTR
		LEFT OUTER JOIN SCPTnAutoParLevel DTL ON MSTR.WraehouseId = DTL.WraehouseId
		WHERE MSTR.IsActive=1
		--and  --AND DTL.IsActive=1
	)TMP 
)TMPP WHERE ROW_NUM=1
)TMPPP WHERE WraehouseId = @WraehouseName

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStStockConsumptionType_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockConsumptionType]
@ItemConsumptionTypeID as int
AS
BEGIN

      SELECT ItemConsumptionIdTypeName,RangeFrom,RangeTo,IsActive FROM SCPStStockConsumptionType 
	  WHERE ItemConsumptionIdTypeId=@ItemConsumptionTypeID
	  ORDER BY ItemConsumptionIdTypeId desc
     
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStStockConsumptionType_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockConsumptionTypeForSearch]
@ItemConsumptionType as varchar(50)
AS
BEGIN
      SELECT ItemConsumptionIdTypeId,ItemConsumptionIdTypeName,RangeFrom,RangeTo,IsActive FROM SCPStStockConsumptionType 
	  WHERE ItemConsumptionIdTypeName LIKE '%'+@ItemConsumptionType+'%' 
	  ORDER BY ItemConsumptionIdTypeId desc
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStStandardValue_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetStandardValue]
@FormCode VARCHAR(50),
@StandardId INT

AS BEGIN

	SELECT StandardFeildValue FROM SCPStStandardValue
	WHERE FormCode=@FormCode AND StandardFeildId=@StandardId

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPCurrentMonthTrailOfReferral]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetCurrentMonthTrailOfReferral]
as
declare @stdAAmountPerDay int =(select sum(StandardAmount)/30 from SCPStConsultantReferral_M);
select (sum(b.Amount)/@stdAAmountPerDay)*100 Perc,DATENAME(D,cast(SaleDate as date))+'-'+DATENAME(m,cast(SaleDate as date)) [Date] from SCPTnSale_M a 
inner join SCPTnSale_D b on a.SaleId=b.SaleId
where PatientCategoryId=2 and cast(SaleDate as date)>= cast(DATEADD(month, DATEDIFF(month, 0, getdate()), 0) as date)
and cast(SaleDate as date)<=cast(DATEADD(DAY, -1, GETDATE()) as date)
and exists (select 1 from SCPStConsultantReferral_M c where c.ConsultantId=a.ConsultantId)
group by DATENAME(D,cast(SaleDate as date))+'-'+DATENAME(m,cast(SaleDate as date)),cast(SaleDate as date)
order by cast(SaleDate as date)
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDailyCompanySalesAndRefund]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptDailyCompanySalesAndRefund]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN

	SET NOCOUNT ON;
	SELECT *, (Sale_Amount - Return_Amount) AS Net_Amount FROM(
		SELECT CONVERT(VARCHAR(50),SCPTnSale_M.SaleDate,105) AS DATE , SCPTnSale_M.NamePrefix +' '+ SCPTnSale_M.FirstName +' '+ SCPTnSale_M.LastName AS SCPTnInPatientName, 
		SCPTnSale_M.PatientIp AS Adm_IP, CAST(SCPStCompany.CompanyName AS VARCHAR(250))AS Company, SUM(SCPTnSale_D.Amount) AS Sale_Amount, 
		ISNULL ((SCPTnSaleRefund_D.ItemRate* SCPTnSaleRefund_D.ReturnQty),0) AS Return_Amount 
		--(SCPTnSaleRefund_D.ItemRate* SCPTnSaleRefund_D.ReturnQty)  AS Return_Amount 
		FROM SCPTnSale_M 
		INNER JOIN SCPTnSale_D ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
		INNER JOIN SCPStCompany ON SCPTnSale_M.CompanyId = SCPStCompany.CompanyId
		LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSale_M.SaleId = SCPTnSaleRefund_M.SaleId
		LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_M.SaleRefundId = SCPTnSaleRefund_D.SaleRefundId
		WHERE PatientTypeId = 2 
		AND PatientIp = '0'
		GROUP BY SCPTnSale_M.FirstName, SCPTnSale_M.LastName, SCPTnSale_M.PatientIp, SCPStCompany.CompanyName,  SCPTnSale_M.NamePrefix, 
		CONVERT(VARCHAR(50),SCPTnSale_M.SaleDate,105),SCPTnSaleRefund_D.ItemRate, SCPTnSaleRefund_D.ReturnQty
		UNION ALL
		SELECT CONVERT(VARCHAR(50),SCPTnSale_M.SaleDate,105) AS DATE , SCPTnSale_M.NamePrefix +' '+ SCPTnSale_M.FirstName +' '+ SCPTnSale_M.LastName AS SCPTnInPatientName, 
		SCPTnSale_M.PatientIp AS Adm_IP, CAST(SCPStCompany.CompanyName AS VARCHAR(250))AS Company, SUM(SCPTnSale_D.Amount) AS Sale_Amount, 
		ISNULL ((SCPTnSaleRefund_D.ItemRate* SCPTnSaleRefund_D.ReturnQty),0) AS Return_Amount 
		--(SCPTnSaleRefund_D.ItemRate* SCPTnSaleRefund_D.ReturnQty)  AS Return_Amount 
		FROM SCPTnSale_M 
		INNER JOIN SCPTnSale_D ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
		INNER JOIN SCPStCompany ON SCPTnSale_M.CompanyId = SCPStCompany.CompanyId
		LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSale_M.PatientIp =  SCPTnSaleRefund_M.PatinetIp
		LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_M.SaleRefundId = SCPTnSaleRefund_D.SaleRefundId
		WHERE PatientTypeId = 2 
		AND PatientIp != '0'
		GROUP BY SCPTnSale_M.FirstName, SCPTnSale_M.LastName, SCPTnSale_M.PatientIp, SCPStCompany.CompanyName,  SCPTnSale_M.NamePrefix, 
		CONVERT(VARCHAR(50),SCPTnSale_M.SaleDate,105),SCPTnSaleRefund_D.ItemRate, SCPTnSaleRefund_D.ReturnQty
	)X where  CONVERT(VARCHAR(50),DATE,105) between @FromDate AND @ToDate
		ORDER BY CONVERT(VARCHAR(50),DATE,105)
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDailySalesRefund]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDailySalesRefund]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM (
		SELECT DISTINCT CONVERT(VARCHAR(50),PH_M.SaleRefundDate,105) AS DATE,PH_M.SaleRefundDate AS TRNSCTN_DATE,PT_TYP.PatientTypeName AS PatientTypeId, PM.PatientIp AS IP_SO,
	CASE WHEN PM.CompanyId != 0  THEN COM_TYP.CompanyName  ELSE ' ' END AS COMPANY_NM,  PH_M.TRNSCTN_ID AS SRCODE, PH_D.ItemCode AS ITMCODE,ITM.ItemName AS ItemName, PH_D.ReturnQty AS ReturnQty, PH_D.ReturnAmount AS RTN_Amount,
		PM.NamePrefix +' '+ PM.FirstName +' '+ PM.LastName AS SCPTnInPatientName, CAT.PatientCategoryName AS PAT_CAT  
		FROM SCPTnSaleRefund_M PH_M 
		INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.SaleRefundId = PH_D.SaleRefundId
		INNER JOIN SCPTnSale_M PM ON PM.PatientIp = PH_M.PatinetIp
		INNER JOIN SCPStPatientType PT_TYP ON PM.PatientTypeId = PT_TYP.PatientTypeId 
		LEFT OUTER JOIN SCPStCompany COM_TYP ON PM.CompanyId = COM_TYP.CompanyId
		INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
		INNER JOIN SCPStPatientCategory CAT ON CAT.PatientCategoryId = PM.PatientCategoryId
		WHERE PatinetIp !='0'
	    and CAST(SaleRefundDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@Todate,103) as date)
	UNION ALL 
	SELECT CONVERT(VARCHAR(50),PH_M.SaleRefundDate,105) AS DATE,PH_M.SaleRefundDate AS TRNSCTN_DATE, PatientTypeName AS PatientTypeId, PM.TRANS_ID AS IP_SO,
		CASE WHEN PM.CompanyId != 0  THEN COM_TYP.CompanyName  ELSE ' ' END AS COMPANY_NM, 
		PH_M.TRNSCTN_ID AS SRCODE, PH_D.ItemCode AS ITMCODE,ITM.ItemName AS ItemName, PH_D.ReturnQty AS ReturnQty, PH_D.ReturnAmount AS RTN_Amount,
		PM.NamePrefix +' '+ PM.FirstName +' '+ PM.LastName AS SCPTnInPatientName ,CAT.PatientCategoryName AS PAT_CAT
		FROM SCPTnSaleRefund_M PH_M 
		INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.SaleRefundId = PH_D.SaleRefundId
		INNER JOIN SCPTnSale_M PM ON PM.SaleId = PH_M.SaleId
		INNER JOIN SCPStPatientType PT_TYP ON PM.PatientTypeId = PT_TYP.PatientTypeId 
		LEFT OUTER JOIN SCPStCompany COM_TYP ON PM.CompanyId = COM_TYP.CompanyId
		INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
		INNER JOIN SCPStPatientCategory CAT ON CAT.PatientCategoryId = PM.PatientCategoryId
		WHERE PM.SaleId != '0'
		 and CAST(SaleRefundDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@Todate,103) as date)
	)X  
		WHERE CAST(SaleRefundDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@Todate,103) as date)
		GROUP BY DATE, SaleRefundDate, PatientTypeId, IP_SO, COMPANY_NM,SRCODE,
		 ITMCODE,ItemName,ReturnQty,RTN_Amount,SCPTnInPatientName,PAT_CAT
	--SELECT * FROM (
	--	SELECT DISTINCT CONVERT(VARCHAR(50),PH_M.TRNSCTN_DATE,105) AS DATE,PT_TYP.PatientTypeName AS PatientTypeId, PM.PatientIp AS IP_SO,
	--CASE WHEN PM.CompanyId != 0  THEN COM_TYP.CompanyName  ELSE ' ' END AS COMPANY_NM,  PH_M.TRNSCTN_ID AS SRCODE, PH_D.ItemCode AS ITMCODE,ITM.ItemName AS ItemName, PH_D.ReturnQty AS ReturnQty, PH_D.ReturnAmount AS RTN_Amount,
	--	PM.NamePrefix +' '+ PM.FirstName +' '+ PM.LastName AS SCPTnInPatientName, CAT.PatientCategoryName AS PAT_CAT  
	--	FROM SCPTnSaleRefund_M PH_M 
	--	INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.TRNSCTN_ID = PH_D.PARENT_TRNSCTN_ID
	--	INNER JOIN SCPTnSale_M PM ON PM.PatientIp = PH_M.PatinetIp
	--	INNER JOIN SCPStPatientType PT_TYP ON PM.PatientTypeId = PT_TYP.PatientTypeId 
	--	LEFT OUTER JOIN SCPStCompany COM_TYP ON PM.CompanyId = COM_TYP.CompanyId
	--	INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
	--	INNER JOIN SCPStPatientCategory CAT ON CAT.PatientCategoryId = PM.PatientCategoryId
	--	WHERE PatinetIp !='0'
	--UNION ALL 
	--SELECT CONVERT(VARCHAR(50),PH_M.TRNSCTN_DATE,105) AS DATE,PT_TYP.PatientTypeName AS PatientTypeId, PM.TRANS_ID AS IP_SO,
	--	CASE WHEN PM.CompanyId != 0  THEN COM_TYP.CompanyName  ELSE ' ' END AS COMPANY_NM, 
	--	PH_M.TRNSCTN_ID AS SRCODE, PH_D.ItemCode AS ITMCODE,ITM.ItemName AS ItemName, PH_D.ReturnQty AS ReturnQty, PH_D.ReturnAmount AS RTN_Amount,
	--	PM.NamePrefix +' '+ PM.FirstName +' '+ PM.LastName AS SCPTnInPatientName ,CAT.PatientCategoryName AS PAT_CAT
	--	FROM SCPTnSaleRefund_M PH_M 
	--	INNER JOIN SCPTnSaleRefund_D PH_D ON PH_M.TRNSCTN_ID = PH_D.PARENT_TRNSCTN_ID
	--	INNER JOIN SCPTnSale_M PM ON PM.TRANS_ID = PH_M.SaleRefundId
	--	INNER JOIN SCPStPatientType PT_TYP ON PM.PatientTypeId = PT_TYP.PatientTypeId 
	--	LEFT OUTER JOIN SCPStCompany COM_TYP ON PM.CompanyId = COM_TYP.CompanyId
	--	INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
	--	INNER JOIN SCPStPatientCategory CAT ON CAT.PatientCategoryId = PM.PatientCategoryId
	--	WHERE SaleId != '0'
	--)X  
	--	WHERE Convert(varchar(10),DATE,105)BETWEEN @Fromdate AND @Todate
END
		

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDamagedItems]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[Sp_SCPRptDamagedItems]
@Year_Month varchar(50)
AS
BEGIN

	SET NOCOUNT ON;
SELECT * FROM (
SELECT SCPTnItemDiscard_D.ItemCode,ITM.ItemName, Quantity, Convert(Varchar(10), ExpiryDate ,105) AS EXP_DATE , Amount,
 SubString(Convert(Varchar(Max), SCPTnItemDiscard_D.ExpiryDate,101), 1, 2) + '-' + Cast(Year(SCPTnItemDiscard_D.ExpiryDate) As Varchar(Max)) as Year_Month
,SCPTnItemDiscard_D. CreatedDate FROM SCPTnItemDiscard_M
 INNER JOIN SCPTnItemDiscard_D 
 ON SCPTnItemDiscard_D.ItemDiscardId = SCPTnItemDiscard_M.ItemDiscardId 
 INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SCPTnItemDiscard_D.ItemCode WHERE DIscardType =2 
 )X WHERE Year_Month = @Year_Month
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDamagedItemsPercentage]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[Sp_SCPRptDamagedItemsPercentage]
@Year_Month varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

SELECT (TOTAL_DAMAGED*100)/TOTAL_STOCK AS EXPRD_ITM FROM
(select 
 (SELECT SUM(CurrentStock) AS CurrentStock FROM SCPTnStock_M WHERE WraehouseId = 2) AS TOTAL_STOCK ,
 (SELECT SUM(Quantity)  FROM
 (SELECT SCPTnItemDiscard_D.ItemCode, Quantity, Convert(Varchar(10), ExpiryDate ,105) AS EXP_DATE,
		 SubString(Convert(Varchar(Max), SCPTnItemDiscard_D.ExpiryDate,101), 1, 2) + '-' + Cast(Year(SCPTnItemDiscard_D.ExpiryDate) As Varchar(Max)) as Year_Month
	      FROM SCPTnItemDiscard_M
		 INNER JOIN SCPTnItemDiscard_D 
		 ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID 
		 WHERE DIscardType =2 AND SCPTnItemDiscard_D.CurrentStock >0 )X WHERE Year_Month = @Year_Month
		 ) AS TOTAL_DAMAGED) tmp
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadItemIssuance]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDeadItemIssuance]
AS
BEGIN
	         DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
	select sum(ItemPackingQuantity*CostPrice) from
	 (
	  select tmppp.ItemCode,STK.StockQuantity,CostPrice from
	  (
		--SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	 --   (
			--SELECT ItemCode,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				group by SCPStItem_M.ItemCode,PRIC.CostPrice HAVING sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
				--)TMP GROUP BY ItemCode,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		    --)TMPP 
			UNION ALL
	   --SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	   --  (
			--SELECT ItemCode,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				group by SCPStItem_M.ItemCode,PRIC.CostPrice
				HAVING SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
			--)TMP GROUP BY ItemCode,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP 
	)tmppp
		LEFT OUTER JOIN  SCPTnPharmacyIssuance_D I_D ON I_D.ItemCode = TMPPp.ItemCode 
		LEFT OUTER JOIN SCPTnStock_D STK ON STK.ItemCode = I_D.ItemCode  AND STK.TransactionDocumentId =I_D.PARENT_TRNSCTN_ID AND WraehouseId =10
         WHERE CAST(I_D.CreatedDate AS date) between CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		GROUP BY TMPPp.ItemCode,STK.StockQuantity,CostPrice
		)tmpppp

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadItemRefundToStore]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDeadItemRefundToStore]
AS
BEGIN
	          DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
	 select isnull(sum(Quantity*CostPrice),0) from
	 (
	  select tmppp.ItemCode,ReturnQty Quantity,CostPrice from
	  (
		--SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
		--	(
				SELECT SCPStItem_M.ItemCode,SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode 
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000'  AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive=1) 
				and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)AND SCPStParLevelAssignment_M.WraehouseId=10
				GROUP BY SCPStItem_M.ItemCode,PRIC.CostPrice HAVING SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				--)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		  --  )TMPP 
			UNION ALL
	  -- SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	  --   (
			--SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode 
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				AND SCPStParLevelAssignment_D.ParLevelId IN (14,16) AND SCPStParLevelAssignment_M.WraehouseId=3 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			    AND CC.WraehouseId=SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive=1) 
				GROUP BY SCPStItem_M.ItemCode,PRIC.CostPrice HAVING SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
		--	)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP 
	)tmppp
		LEFT OUTER JOIN  SCPTnReturnToStore_D I_D ON I_D.ItemCode = TMPPp.ItemCode 
        WHERE CAST(I_D.CreatedDate AS date) between CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		GROUP BY TMPPp.ItemCode,I_D.ReturnQty,CostPrice
		)tmpppp
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadItemReturnToSup]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDeadItemReturnToSupplier]
AS
BEGIN
	          DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
	 select isnull(sum(Quantity*CostPrice),0) from
	 (
	  select tmppp.ItemCode,ReturnQty Quantity,CostPrice from
	  (
		--SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
		--	(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode 
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC 
				WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)  AND SCPStParLevelAssignment_M.WraehouseId=10
				AND CC.WraehouseId=SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,PRIC.CostPrice HAVING SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
				--)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		  --  )TMPP 
			UNION ALL
	  -- SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	  --   (
			--SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode 
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			    AND CC.WraehouseId=SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive=1) 
				WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16) AND SCPStParLevelAssignment_M.WraehouseId=3
				GROUP BY SCPStItem_M.ItemCode,PRIC.CostPrice HAVING SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0 
				OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
		--	)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP 
	)tmppp
		LEFT OUTER JOIN  SCPTnReturnToSupplier_D I_D ON I_D.ItemCode = TMPPp.ItemCode 
        WHERE CAST(I_D.CreatedDate AS date) between CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		GROUP BY TMPPp.ItemCode,I_D.ReturnQty,CostPrice
		)tmpppp
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadItemSale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetDeadItemSale]
AS
BEGIN
	          DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
	 select sum(Quantity*CostPrice) from
	 (
	  select tmppp.ItemCode,Quantity,CostPrice from
	  (
		--SELECT TMPP.ItemCode,CostPrice FROM
	 --   (
			--SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				group by SCPStItem_M.ItemCode,PRIC.CostPrice having SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
				 OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
				--)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		    --)TMPP 
			UNION ALL
	  -- SELECT TMPP.ItemCode,ItemName,CostPrice FROM
	  --   (
			--SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			--(
				SELECT SCPStItem_M.ItemCode,sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END) AS MinLevel,
				sum(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END )AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				group by SCPStItem_M.ItemCode,PRIC.CostPrice having SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
				 OR SUM(CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END)=0
		--	)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP 
	)tmppp
		LEFT OUTER JOIN  SCPTnSale_D I_D ON I_D.ItemCode = TMPPp.ItemCode 
        WHERE CAST(I_D.CreatedDate AS date) between CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		GROUP BY TMPPp.ItemCode,I_D.Quantity,CostPrice
		)tmpppp
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadStock]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDeadStock]
@WraehouseName INT
AS
BEGIN
SELECT CASE WHEN @WraehouseName=3 THEN phm ELSE mss END AS DEAD_STOCK FROM
(
	SELECT SUM(PHM*CostPrice) AS phm,SUM(MSS*CostPrice) AS mss from
	 (
    select distinct ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel,PHM,MSS,CostPrice from 
	 (
	   SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	   WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) AS PHM, ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	   WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) as MSS,CostPrice FROM
	    (
			SELECT ItemCode,ItemName,0 AS pos_MinLevel,0 AS pos_MaxLevel,SUM(MinLevel) AS MSS_MinLevel,
			SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
			(
				SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
				)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		    )TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel
			UNION ALL
	   SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	   WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) as PHM,ISNULL((SELECT sum(CurrentStock) 
	   FROM SCPTnStock_M WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) AS MSS,CostPrice FROM
	    (
			SELECT ItemCode,ItemName,SUM(MinLevel) AS pos_MinLevel,SUM(MaxLevel) AS pos_MaxLevel,0 AS MSS_MIN,0 AS MSS_MAX,CostPrice FROM
			(
				SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
			    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
			)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		)TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX
	)tmppp
)TMPPP
)TMPPPP
-- DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
--		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
--		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
--		  DECLARE @FLAG AS BIT = 0;								  --For loop


--		  WHILE @FLAG = 0
--		  BEGIN
--				SET @FLAG = 1;
--				IF @REPORT_DAY = 1     -- Sunday Condition
--				BEGIN 
--					SET @FLAG = 0;
--					SET @DAYS_DIFF = @DAYS_DIFF +1;
--					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
--					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
--				END 
--				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
--				BEGIN
--					SET @FLAG = 0;
--					SET @DAYS_DIFF = @DAYS_DIFF +1;
--					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
--					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
--				END
--		  END

--SELECT CASE WHEN @WraehouseName=3 THEN phm ELSE mss END AS DEAD_STOCK FROM
--(
--	SELECT SUM(CurrentStock*CostPrice) AS mss,SUM(PHM*CostPrice) AS phm from
--	 (
--	    SELECT TMPP.ItemCode,ItemName,STCK.BatchNo,Isnull((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
--	    WHERE  ItemCode = TMPP.ItemCode AND WraehouseId = 10 AND BatchNo = STCK.BatchNo 
--		AND Cast(CreatedDate AS DATE) < Cast(CONVERT(DATE, @REPORT_DATE, 103) AS   DATE) 
--		ORDER  BY CreatedDate DESC), 0) AS CurrentStock,ISNULL(Isnull((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
--	    WHERE  ItemCode = TMPP.ItemCode AND WraehouseId = 3 AND BatchNo = STCK.BatchNo 
--		AND Cast(CreatedDate AS DATE) < Cast(CONVERT(DATE, @REPORT_DATE, 103) AS   DATE) 
--		ORDER  BY CreatedDate DESC), 0),0) AS PHM,CostPrice FROM
--	    (
--			SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
--			(
--				SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
--				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
--				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
--				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
--				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
--				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
--				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
--				)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
--		    )TMPP INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=TMPP.ItemCode AND STCK.WraehouseId=10 
--			GROUP BY TMPP.ItemCode,ItemName,STCK.BatchNo,CurrentStock,CostPrice
--			UNION ALL
--	   SELECT TMPP.ItemCode,ItemName,STCK.BatchNo,ISNULL(Isnull((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
--	    WHERE  ItemCode = TMPP.ItemCode AND WraehouseId = 10 AND BatchNo = STCK.BatchNo 
--		AND Cast(CreatedDate AS DATE) < Cast(CONVERT(DATE, @REPORT_DATE, 103) AS   DATE) 
--		ORDER  BY CreatedDate DESC), 0),0) AS MSS,Isnull((SELECT TOP 1 ItemBalance FROM SCPTnStock_D 
--	    WHERE  ItemCode = TMPP.ItemCode AND WraehouseId = 3 AND BatchNo = STCK.BatchNo 
--		AND Cast(CreatedDate AS DATE) < Cast(CONVERT(DATE, @REPORT_DATE, 103) AS   DATE) 
--		ORDER  BY CreatedDate DESC), 0) AS CurrentStock,CostPrice FROM
--	    (
--			SELECT ItemCode,ItemName,SUM(MinLevel) AS MSS_MinLevel,SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
--			(
--				SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
--				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
--				INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
--				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
--				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
--				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
--			    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
--			)TMP GROUP BY ItemCode,ItemName,CostPrice HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
--		)TMPP INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=TMPP.ItemCode AND STCK.WraehouseId=3 
--		GROUP BY TMPP.ItemCode,ItemName,STCK.BatchNo,CurrentStock,CostPrice
--	)TMPPP
--)TMPPPP
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDeadStockDashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetDeadStockForDashboard]

	AS BEGIN

	DECLARE @STOCK_VALUE MONEY,@DEAD_STOCK_VALUE MONEY
	SET @STOCK_VALUE=(SELECT SUM(CurrentStock*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice 
					ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
					INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode
					LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPTnStock_M.ItemCode AND SCPTnStock_M.BatchNo = SCPTnGoodReceiptNote_D.BatchNo
					AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
					WHERE SCPTnGoodReceiptNote_D.ItemCode = SCPTnStock_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
					INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode 
					AND ItemRateId=(SELECT MAX(ItemRateId) FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate 
					BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)	WHERE SCPStItem_M.IsActive=1 )
	
	SET @DEAD_STOCK_VALUE =(SELECT SUM(CurrentStock*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) FROM 
	 (
		SELECT ItemCode FROM	
		(
			SELECT ItemCode,AvgPerDay,AVG_SALE,CASE WHEN AvgPerDay=0 AND AVG_SALE=0 THEN 0 
			WHEN AvgPerDay=0 THEN AVG_SALE*100 ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM
			(
				SELECT ItemCode,AvgPerDay,
				CAST(SOLD_QTY AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()) AS AVG_SALE FROM
				(
					SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(Quantity),0) AS SOLD_QTY FROM SCPStItem_M
					LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
					AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
					INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
					AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.ParLevelAssignmentId) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
					AND CC.WraehouseId=10 AND CC.IsActive=1)
					WHERE SCPStItem_M.IsActive=1 
					GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay
				)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY
			)TMPP GROUP BY ItemCode,AvgPerDay,AVG_SALE
		)TMPPP,SCPStStockConsumptionType CT WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo AND ItemConsumptionIdTypeId=4
	)TMPPPP
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = ItemCode --AND WraehouseId=@WraehouseName
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=SCPTnStock_M.BatchNo 
	AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D WHERE SCPTnGoodReceiptNote_D.ItemCode = ItemCode 
								AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC)
	LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=ItemCode))

	SELECT ROUND(@DEAD_STOCK_VALUE,0) DEAD_STOCK_VALUE,ROUND(@DEAD_STOCK_VALUE*100/@STOCK_VALUE,0) AS DEAD_STOCK_PER
	
	END
	
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDeligation_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetUsersForDelication]
	
	@usrId as int
AS
BEGIN
	
	SET NOCOUNT ON;

       SELECT DISTINCT UserName as EmployeeName, UserId, ADAccount FROM SCPStUser_M
    WHERE SCPStUser_M.IsActive=1 and UserId != @usrId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDeligation_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDeligatedUserDetail]
@ADacc as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;
			  select  UserId,EmployeeGroupId 
		  ,CASE WHEN IsDeligated = 1 THEN 
		  (SELECT DeligatedUserId FROM SCPStDeligation INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = UserId 
		  WHERE SCPStUser_M.ADAccount= @ADacc and SCPStDeligation.CreatedDate  
		  in (select MAX(SCPStDeligation.CreatedDate) from SCPStDeligation where UserId = SCPStUser_M.UserId) 
		  and GETDATE() between SCPStDeligation.FromDate and SCPStDeligation.ToDate group by DeligatedUserId)  END AS DEL
		  from SCPStUser_M
	  where ADAccount=@ADacc
		 -- select  UserId,EmployeeGroupId 
		 -- ,CASE WHEN IsDeligated = 1 THEN 
		 -- (SELECT DeligatedUserId FROM SCPStDeligation INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = UserId 
		 -- WHERE SCPStUser_M.ADAccount= @ADacc and SCPStDeligation.CreatedDate  in (select MAX(SCPStDeligation.CreatedDate) from SCPStDeligation where UserId = SCPStUser_M.UserId) group by DeligatedUserId)  END AS DEL
		 -- from SCPStUser_M
	  --where ADAccount=@ADacc
		 -- select UserId,EmployeeGroupId 
		 -- ,CASE WHEN IsDeligated = 1 THEN 
		 -- (SELECT DeligatedUserId FROM SCPStDeligation INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = UserId 
		 -- WHERE SCPStUser_M.ADAccount= @ADacc)  END AS DEL
		 -- from SCPStUser_M
	  --where ADAccount= @ADacc
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDeligation_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetDeligatedUser]
	@UsrId as int
AS
BEGIN
	
	SET NOCOUNT ON;

   SELECT UserName, ADAccount, SCPStUser_M.UserPassword FROM SCPStUser_M WHERE UserId = @UsrId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStDeligation_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetUserDeligation]
@UsrId as int	
AS
BEGIN
	SET NOCOUNT ON;

   SELECT * FROM SCPStDeligation WHERE SCPStDeligation.UserId = @UsrId
AND GETDATE() < SCPStDeligation.ToDate
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDemandVsIssuancePrcntg]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetLastDayDemandvsIssuencePercentage]

AS BEGIN

	DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
	DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
	DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
	DECLARE @FLAG AS BIT = 0;								  --For loop


	WHILE @FLAG = 0
	BEGIN
		SET @FLAG = 1;
		IF @REPORT_DAY = 1     -- Sunday Condition
		BEGIN 
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END 
		IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
		BEGIN
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END
	END

	SELECT CAST((ISSU_ITEM*100)/count(ItemCode) AS VARCHAR(50)) AS DmndVsIssuancePrcntg FROM
	(
		SELECT ItemCode,COUNT(ItemCode) DMND_ITM,(SELECT COUNT(ItemCode) FROM
		(
			SELECT DISTINCT ItemCode FROM SCPTnPharmacyIssuance_D WHERE CAST(SCPTnPharmacyIssuance_D.CreatedDate AS date) 
			BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
			)TMPP
		) AS ISSU_ITEM FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) 
		BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date) GROUP BY ItemCode
	)TMP group by ISSU_ITEM

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDemandvsIssuence]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetLastDayDemandvsIssuence] 

AS
BEGIN


--DECLARE  @FROM_DT AS VARCHAR(50)=FORMAT(GETDATE()-1, 'dddd') ,@ToDate AS VARCHAR(50)=FORMAT(GETDATE()-1, 'dddd')

--SET @FROM_DT = case @FROM_DT when 	'Sunday' then getdate() -2 else getdate() - 1 end 
--set @ToDate = case @ToDate when 'Sunday' then getdate() - 2 else getdate() -1 end

	      DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
SELECT ISSU_ITEM,count(ItemCode) AS DMND_ITM FROM

(

 SELECT ItemCode,COUNT(ItemCode) DMND_ITM,(SELECT COUNT(ItemCode) FROM

       (SELECT DISTINCT ItemCode FROM SCPTnPharmacyIssuance_D WHERE CAST(SCPTnPharmacyIssuance_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

       )TMPP) AS ISSU_ITEM

FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

GROUP BY ItemCode

)TMP group by ISSU_ITEM


END

--SELECT SUM(DMND_ITM) AS DMND_ITM,SUM(ISSU_ITEM) AS ISSU_ITEM FROM

--(

--SELECT PARENT_TRNSCTN_ID,COUNT(ItemCode) DMND_ITM,

--(SELECT  COUNT(ItemCode) FROM SCPTnPharmacyIssuance_D WHERE DemandId=SCPTnDemand_D.PARENT_TRNSCTN_ID) AS ISSU_ITEM

--FROM SCPTnDemand_D WHERE CAST(SCPTnDemand_D.CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)

--GROUP BY PARENT_TRNSCTN_ID

--)TMP
 
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDmnDAvg]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetDemand30DaysAvg]

AS BEGIN

	SELECT AVG(MANUAL_AMT) AS MANUAL_DMND_AMT,AVG(AUTO_AMT) AS AUTO_DMND_AMT FROM
	(
		SELECT DAY_DATE,ISNULL(SUM(MANUAL_AMT),0) AS MANUAL_AMT,ISNULL(SUM(AUTO_AMT),0) AS AUTO_AMT FROM
		(
		SELECT CAST(TRNSCTN_DATE AS DATE) AS DAY_DATE,
		CASE WHEN DemandType='A' THEN SUM(DD.DemandQty*CostPrice) END AS AUTO_AMT,
		CASE WHEN DemandType='M' THEN SUM(DD.DemandQty*CostPrice) END AS MANUAL_AMT FROM SCPTnDemand_M MM
		INNER JOIN SCPTnDemand_D DD ON MM.TRNSCTN_ID = DD.PARENT_TRNSCTN_ID
		LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = DD.ItemCode AND PRIC.FromDate <= TRNSCTN_DATE and PRIC.ToDate >= TRNSCTN_DATE
		WHERE CAST(TRNSCTN_DATE AS DATE) BETWEEN DATEADD(DAY,-30,GETDATE()) AND GETDATE() AND MM.IsActive=1
		GROUP BY CAST(TRNSCTN_DATE AS DATE),DemandType
		)TMP GROUP BY DAY_DATE
	)TMPP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPDoctorWiseSales]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptConsultantWiseSale]
@FromDate VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

SELECT DATE,(cast(round( case when isnull(AvgPatients,0)/30 =0 then 0 else PRESCRIPTN/(cast((isnull(AvgPatients,0)/30)  as float)) end
 ,2) as float))*100 AvgPresc,isnull(AvgPatients,0)/30 TotalOPD,case when NoOfPatients>0 
 then round(cast((PRESCRIPTN/NoOfPatients)*100 as float),0) else 0 end ReferralPercentage
,ConsultantName,PRESCRIPTN , AMOUNT,(SELECT SUM(AMOUNT) FROM
( 	
    SELECT DATE,AvgPatients,NoOfPatients,COUNT(X.Prescription) AS PRESCRIPTN, SUM(X.Amount) AS AMOUNT , 
    CONS.ConsultantName AS ConsultantName FROM
	(
		SELECT PHM.TRANS_ID AS Prescription,CONVERT(VARCHAR(10), PHM.TRANS_DT, 105) AS DATE,SUM(ROUND(Quantity*ItemRate,0)) AS Amount, 
		PHM.ConsultantId AS CONSULTANT	FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
		WHERE CAST(PHM.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.PatientCategoryId=2
		GROUP BY PHM.TRANS_ID,  PHM.ConsultantId, CONVERT(VARCHAR(10), PHM.TRANS_DT, 105)
	)X INNER JOIN SCPStConsultant CONS ON X.CONSULTANT = CONS.HIMSConsultantId
GROUP BY CONS.ConsultantName,DATE
) CTE)AS TOTAL_AMT FROM
( 	SELECT DATE,CRP49.AvgPatients,round((((cast(CRP49.AvgPatients as float)/100)*crp49.Percentage)),2) NoOfPatients,
    COUNT(X.Prescription) AS PRESCRIPTN, SUM(X.Amount) AS AMOUNT , CONS.ConsultantName AS ConsultantName FROM
	(
		SELECT PHM.TRANS_ID AS Prescription,CONVERT(VARCHAR(10), PHM.TRANS_DT, 105) AS DATE,  
		SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.ConsultantId AS CONSULTANT	FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
		WHERE CAST(PHM.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.PatientCategoryId=2
		GROUP BY PHM.TRANS_ID,  PHM.ConsultantId, CONVERT(VARCHAR(10), PHM.TRANS_DT, 105)
	)X INNER JOIN SCPStConsultant CONS ON X.CONSULTANT = CONS.HIMSConsultantId 
	LEFT JOIN SCPStConsultantReferral_M CRP49 ON CONS.HIMSConsultantId=CRP49.ConsultantId
  GROUP BY CONS.ConsultantName, DATE,CRP49.AvgPatients,crp49.Percentage
) CTE_ABC ORDER BY CAST(CONVERT(date,DATE,103) AS date) 

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPEmployeeWiseSale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptEmployeeWiseSale]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN
	
SELECT EMP_CODE,PT_NAME,EMP_NAME,SL_QTY,ReturnQty,AMOUNT,RTRN_AMOUNT,(AMOUNT-RTRN_AMOUNT) AS NetAmount FROM
(
  SELECT EMP_CODE,EMP_NAME,PT_NAME,SUM(SL_QTY) AS SL_QTY,SUM(ReturnQty) AS ReturnQty,SUM(AMOUNT) AS AMOUNT,SUM(RTRN_AMOUNT) AS RTRN_AMOUNT FROM
   (
    SELECT SCPTnSale_M.NamePrefix+' '+FirstName+' ' +LastName AS PT_NAME,SCPTnSale_M.CareOff AS EMP_CODE,
	SCPStEmployee.EmployeeName AS EMP_NAME,ISNULL(SUM(SCPTnSale_D.Quantity),0) AS SL_QTY,isnull(SUM(ROUND(Quantity*ItemRate,0)) ,0) AS AMOUNT,
	(SELECT isnull(SUM(PHD.ReturnQty),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.PARENT_TRNSCTN_ID = PHM.TRNSCTN_ID 
	 AND PHM.SaleRefundId = SCPTnSale_M.SaleId AND CAST(PHM.TRNSCTN_DATE as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)   and PHM.IsActive=1) AS ReturnQty,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.PARENT_TRNSCTN_ID = PHM.TRNSCTN_ID 
	 AND PHM.SaleRefundId = SCPTnSale_M.SaleId AND CAST(PHM.TRNSCTN_DATE as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)   and PHM.IsActive=1) AS RTRN_AMOUNT FROM SCPTnSale_M 
	 INNER JOIN SCPStEmployee ON SCPTnSale_M.CareOff = SCPStEmployee.EmployeeCode AND SCPTnSale_M.CareOffCode=1 
	 INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
	 WHERE SCPTnSale_M.SaleId!='0' AND SCPTnSale_M.PatientIp='0'  and SCPTnSale_M.IsActive=1 AND 
	 CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	  GROUP BY SCPTnSale_M.NamePrefix,FirstName,LastName,SCPTnSale_M.CareOff,SCPStEmployee.EmployeeName,SCPTnSale_M.SaleId
	 UNION ALL 
	 SELECT SCPTnSale_M.NamePrefix+' '+SCPTnInPatient.FirstName+' ' +SCPTnInPatient.LastName AS PT_NAME,SCPTnSale_M.CareOff,
	 SCPStEmployee.EmployeeName AS EMP_NAME,ISNULL(SUM(SCPTnSale_D.Quantity),0) AS SL_QTY,isnull(SUM(ROUND(Quantity*ItemRate,0)) ,0) AS AMOUNT,
	 (SELECT isnull(SUM(PHD.ReturnQty),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.PARENT_TRNSCTN_ID = PHM.TRNSCTN_ID 
	 AND PHM.PatinetIp = SCPTnSale_M.PatientIp AND CAST(PHM.TRNSCTN_DATE as date) 
	 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)   and PHM.IsActive=1) AS ReturnQty,
	(SELECT isnull(SUM(PHD.ReturnAmount),0) FROM SCPTnSaleRefund_M PHM
	 INNER JOIN SCPTnSaleRefund_D PHD ON PHD.PARENT_TRNSCTN_ID = PHM.TRNSCTN_ID AND PHM.PatinetIp = SCPTnSale_M.PatientIp 
	 AND CAST(PHM.TRNSCTN_DATE as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	 AND CAST(CONVERT(date,@ToDate,103) as date)  and PHM.IsActive=1) AS RTRN_AMOUNT FROM SCPTnSale_M 
	 INNER JOIN SCPStEmployee ON SCPTnSale_M.CareOff = SCPStEmployee.EmployeeCode AND SCPTnSale_M.CareOffCode=1 
	 INNER JOIN SCPTnInPatient ON SCPTnInPatient.PatientIp = SCPTnSale_M.PatientIp
	 INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId WHERE SCPTnSale_M.PatientIp!='0' and SCPTnSale_M.IsActive=1 AND 
	 CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	 GROUP BY SCPTnSale_M.NamePrefix,SCPTnInPatient.FirstName,SCPTnInPatient.LastName,SCPTnSale_M.CareOff,SCPStEmployee.EmployeeName,SCPTnSale_M.PatientIp
	 )TMP1 GROUP BY EMP_CODE,EMP_NAME,PT_NAME
)TMP2
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPExpiredItemsDtl]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiredItems]
AS
BEGIN
	SELECT ItemName,BatchNo,CurrentStock,CONVERT(VARCHAR(10), ISSUE_DATE, 105) AS ISSUE_DATE,
	CONVERT(VARCHAR(10),EXP_DATE, 105) AS EXP_DATE FROM
	(
		SELECT SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock,
		MAX(SCPTnStock_M.CreatedDate) AS ISSUE_DATE,MAX(SCPTnGoodReceiptNote_D.ExpiryDate) EXP_DATE FROM SCPStItem_M
		INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode=SCPTnStock_M.ItemCode AND SCPTnStock_M.WraehouseId=3
		INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
		AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
		GROUP BY SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock
	)
 TMP WHERE CurrentStock>0 AND EXP_DATE<GETDATE()

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPExpiredItemsPrcntg]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiredItemsPercentage]
AS
BEGIN

WITH CTE AS
(
 SELECT COUNT(ItemCode) AS EXPRY_ITM,(SELECT COUNT(ItemCode) FROM
 (
   SELECT SCPTnStock_M.ItemCode,SUM(CurrentStock) AS CurrentStock,MAX(ExpiryDate) AS EXP_DATE FROM SCPTnStock_M 
   INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
   AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
   AND SCPTnStock_M.WraehouseId=3  GROUP BY SCPTnStock_M.ItemCode
 )TMP WHERE CurrentStock>0) AS TTL_ITM FROM
  (
   SELECT DISTINCT ItemCode FROM
   (
    SELECT SCPTnStock_M.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,
	max(SCPTnGoodReceiptNote_D.ExpiryDate) AS EXP_DATE FROM SCPTnStock_M
    INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
    AND SCPTnStock_M.WraehouseId=3 GROUP BY SCPTnStock_M.ItemCode,CurrentStock,SCPTnStock_M.BatchNo
	 )TMP WHERE CurrentStock>0 AND EXP_DATE<GETDATE()
  )TT
)SELECT (EXPRY_ITM*100)/TTL_ITM AS EXPRD_ITM FROM CTE

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPExpiryItemDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryItems]
@WraehouseId AS INT
AS
BEGIN
	SELECT ClassName,ItemCode,ItemName,BatchNo,DosageName,CurrentStock,CONVERT(VARCHAR(10), ISSUE_DATE, 105) AS ISSUE_DATE,
	CONVERT(VARCHAR(10),EXP_DATE, 105) AS EXP_DATE FROM
   (
    SELECT CONVERT(VARCHAR(50),ClassName) as ClassName ,SCPStItem_M.ItemCode,SCPStItem_M.ItemName,DosageName,
	SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock,
    MAX(SCPTnStock_M.CreatedDate) AS ISSUE_DATE,MAX(SCPTnGoodReceiptNote_D.ExpiryDate) EXP_DATE FROM SCPStItem_M
    INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode=SCPTnStock_M.ItemCode AND SCPTnStock_M.WraehouseId=@WraehouseId
    INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
	INNER JOIN SCPStClassification on SCPStClassification.ClassId = SCPStItem_M.ClassId
	INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
    GROUP BY ClassName,SCPStItem_M.ItemCode,SCPStItem_M.ItemName,DosageName,SCPTnStock_M.BatchNo,SCPTnStock_M.CurrentStock
   )
   TMP WHERE CurrentStock>0 AND EXP_DATE BETWEEN CONVERT(DATE,GETDATE()) 
   AND DATEADD(month,6, CONVERT(DATE,GETDATE())) ORDER BY ItemName

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPExpiryItemsPrcntg]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetExpiryItemsPercentage]
AS
BEGIN
	WITH CTE AS
	(
	 SELECT COUNT(ItemCode) AS EXPRY_ITM,(SELECT COUNT(ItemCode) FROM
	 (
	   SELECT SCPTnStock_M.ItemCode,SUM(CurrentStock) AS CurrentStock,MAX(ExpiryDate) AS EXP_DATE FROM SCPTnStock_M 
	   INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
	   AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
	   AND SCPTnStock_M.WraehouseId=3  GROUP BY SCPTnStock_M.ItemCode
	 )TMP WHERE CurrentStock>0) AS TTL_ITM FROM
	  (
	   SELECT DISTINCT ItemCode FROM
	   (
		SELECT SCPTnStock_M.ItemCode,SCPTnStock_M.BatchNo,CurrentStock,max(SCPTnGoodReceiptNote_D.ExpiryDate) AS EXP_DATE FROM SCPTnStock_M
		INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnStock_M.ItemCode=SCPTnGoodReceiptNote_D.ItemCode 
		AND SCPTnStock_M.BatchNo=SCPTnGoodReceiptNote_D.BatchNo
		AND SCPTnStock_M.WraehouseId=3 GROUP BY SCPTnStock_M.ItemCode,CurrentStock,SCPTnStock_M.BatchNo
		)TMP WHERE CurrentStock>0 AND EXP_DATE BETWEEN CONVERT(DATE,GETDATE()) AND DATEADD(month,6, CONVERT(DATE,GETDATE()))
	  )TT
)SELECT (EXPRY_ITM*100)/TTL_ITM AS EXPRD_ITM FROM CTE
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetConsultantDataWithReasonId]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[Sp_SCPGetConsultantDataWithReasonId]
 @zoneID int,@startDate datetime,@endDate datetime
 as
 
select cast(row_number() over(order by a.ConsultantId) as varchar(max)) rn,crp20.ConsultantName,a.StandardAmount,a.ActualAmount,a.Diff,a.StandardAvgPrescription,a.ReferralPercentage,b.ReasonIdDescription from SCPStConsultantReferralComments a 
inner join SCPStConsultant crp20 on a.ConsultantId=crp20.ConsultantId
inner join SCPStConsultantReferralReasonId b on a.ReasonIdID=b.id
where ZoneId=@zoneID and cast(a.FromDate as date)>=cast(@startDate as date) and cast(a.ToDate as date)>=cast(@endDate as date)


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetConsultantSalesDataForCurrentMonth]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE procedure [dbo].[Sp_SCPGetConsultantSalesDataForCurrentMonth]
	as
	Begin
	declare @date date =cast(convert(date,GETDATE(),103)as date),@totalSpendDays int,@firstDate date;
	--select @date
	select @totalSpendDays=(select ABS(SUBSTRING(cast(@date as varchar(max)),len(@date)-2,len(cast(convert(date,@date,103)as date))))-1);
	--select @totalSpendDays
	set @totalSpendDays = case when @totalSpendDays=0 then 1 else @totalSpendDays end
	select @firstDate=(select (concat(concat(concat(concat(DATEPART(YEAR,getdate()),'-'),DATEPART(MONTH,getdate())),'-'),1)));
	--select @firstDate
	with cal as (
	SELECT 0 StandardAmount,-SUM(ROUND(ReturnAmount,0))  AS ActualAmount,0 Difference,0 ReferralPercentage
	FROM SCPTnSaleRefund_M PHM
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID AND PHM.PatinetIp='0'
	WHERE PHM.IsActive=1 and pmm.PatientCategoryId=2
	and cast(CONVERT(date,pmm.TRANS_DT ,103) as date) >= cast(CONVERT(date,@firstDate ,103) as date) 
	and cast(CONVERT(date,pmm.TRANS_DT ,103) as date) <= cast(CONVERT(date,GETDATE() ,103) as date)
	union all
	select 0 'StandardAmount',sum(round(SCPTnSale_D.Amount,0))/*- sum(round(isnull(ReturnAmount,0),0))*/ 'ActualAmount',0 Difference,0 ReferralPercentage 
	from SCPTnSale_M SCPTnSale_M 
	inner join SCPTnSale_D SCPTnSale_D on SCPTnSale_D.SaleId = SCPTnSale_M.SaleId
	--left join SCPTnSaleRefund_M phm2m on phm2m.SaleRefundId = SCPTnSale_M.SaleId 
	--left join SCPTnSaleRefund_D phm2d on phm2m.TRNSCTN_ID=phm2d.PARENT_TRNSCTN_ID and phm2m.PatinetIp='0'
	where SCPTnSale_M.PatientCategoryId=2 
	and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103) as date) >= cast(CONVERT(date,@firstDate ,103) as date) 
	and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103) as date) <= cast(CONVERT(date,GETDATE() ,103) as date)
	union 
	select (sum(StandardAmount)/30)*@totalSpendDays,0 ,0,round((sum((((cast(AvgPatients as float)/100)*Percentage)))/sum(AvgPatients))*100,0) ReferralPercentage   from SCPStConsultantReferral_M crp49
	)
	select sum(StandardAmount) StandardAmount,sum(ActualAmount) ActualAmount,sum(ActualAmount)-sum(StandardAmount) Difference,(sum(ActualAmount)/sum(StandardAmount))*100 DiffAvg,sum(ReferralPercentage) ReferralPercentage from cal
	end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSCPStConsultantReferral_MData]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPGetSCPStConsultantReferral]

AS
begin

;with a as (


select crp49.ConsultantId,crp20.ConsultantName Name,crp49.StandardAmount StandardAmount
,crp49.PerPrescripAmt
,Percentage  Percentage,crp49.AvgPatients
,round((((cast(crp49.AvgPatients as float)/100)*Percentage)),0) NoOfSCPTnInPatients

from SCPStConsultantReferral_M crp49
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
where crp20.IsActive=1 and crp49.StandardAmount>0 

)
--select sum(rtrn) from a

select cast(row_number() over(order by Name) as varchar(max)) rn
,Name,AvgPatients,a.Percentage,a.NoOfSCPTnInPatients,a.PerPrescripAmt
,isnull(StandardAmount,0) StandardAmount From a
  end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemsDeadOnZeroByWraehouseName]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetItemsDeadOnZeroByWraehouseName]
@WraehouseId int

AS BEGIN

  SELECT COUNT(ItemCode) as ItemsonZero  FROM 
	(
	    SELECT SCPStItem_M.ItemCode,isnull(SUM(STCK.CurrentStock),0)  AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId=@WraehouseId
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode having isnull(SUM(STCK.CurrentStock),0)=0
	)TMP WHERE ItemCode IN( SELECT ItemCode FROM
			(
				SELECT SCPStItem_M.ItemCode,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		   	UNION ALL
			SELECT ItemCode FROM
			(
				SELECT SCPStItem_M.ItemCode,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
			)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		) 

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetItemsOnZeroByWraehouseName]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[Sp_SCPGetItemsOnZeroByWraehouseName]
@WraehouseId int

AS BEGIN

 SELECT COUNT(ItemCode) as ItemsonZero  FROM 
	(
	    SELECT SCPStItem_M.ItemCode,isnull(SUM(STCK.CurrentStock),0)  AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId=@WraehouseId
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode having isnull(SUM(STCK.CurrentStock),0)=0
	)TMP WHERE ItemCode NOT IN( SELECT ItemCode FROM
			(
				SELECT SCPStItem_M.ItemCode,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
				)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		   	UNION ALL
			SELECT ItemCode FROM
			(
				SELECT SCPStItem_M.ItemCode,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
				CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel FROM SCPStItem_M
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
				INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
				AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
			)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		)

END
		
		


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetLast12MonthTargetAchieved]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetLast12MonthTargetAchieved]
as
declare @startDate date=cast(DATEADD(YEAR, -1, DATEADD(MONTH, DATEDIFF(MONTH, '19000101', GETDATE()), '19000101')) as date),
@EndDate date= cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), -1) as date),
@stdAmount int =(select sum(StandardAmount) from SCPStConsultantReferral_M where IsActive=1);

with a as (
select month(cast(a.TRANS_DT as date)) [Month] ,year(cast(a.TRANS_DT as date)) [Year]
--DATENAME(M,cast(TRANS_DT as date))+'-'+DATENAME(YYYY,cast(TRANS_DT as date)) [month]
,(sum(Amount)/@stdAmount)*100 Sales 
from SCPTnSale_M a 
inner join SCPTnSale_D b 
on a.TRANS_ID=b.PARNT_TRANS_ID
inner join SCPStConsultant c on a.ConsultantId=c.ConsultantId
where a.PatientCategoryId=2 and cast(a.TRANS_DT as date)>=@startDate and cast(a.TRANS_DT as date)<=@EndDate and a.ConsultantId<>0 
group by month(cast(a.TRANS_DT as date)),year(cast(a.TRANS_DT as date)) 
)
select (select dbo.GetMonthName(Month )as data)+'-'+cast(Year as varchar(max)) Column1,Sales from a order by Month

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGetSalesByPatientCategory]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPGetSalesByPatientCategory]
	@StartDate datetime,
	@EndDate datetime
	as
	begin
	
WITH sumValData as(
select a.PatientCategoryName,cast(sum(round(Quantity*SCPTnSale_D.ItemRate,0) )as bigint) sumVal from SCPStPatientCategory a 
	left join SCPTnSale_M b  on 
	a.PatientCategoryId=b.PatientCategoryId and cast(CONVERT(date,b.TRANS_DT ,103) as date)>=Convert(date,cast( @StartDate as date),103)  
	and cast(CONVERT(date,b.TRANS_DT ,103) as date)<=Convert(date,cast( @EndDate as date),103) 
	inner join SCPTnSale_D SCPTnSale_D on SCPTnSale_D.SaleId = b.TRANS_ID
	group by a.PatientCategoryName
	UNION ALL
	SELECT PatientCategoryName,cast(-SUM(ROUND(ReturnAmount,0)) as bigint)  AS sumVal
	FROM SCPTnSaleRefund_M PHM
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID AND PHM.PatinetIp='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE)>=Convert(date,cast( @StartDate as date),103) AND CAST(PHM.TRNSCTN_DATE AS DATE)<=Convert(date,cast( @EndDate as date),103)
	 AND PHM.IsActive=1
	GROUP BY PatientCategoryName
	UNION ALL
	SELECT PatientCategoryName,cast(-SUM(ROUND(ReturnAmount,0)) as bigint)  AS sumVal
	FROM SCPTnSaleRefund_M PHM
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE)>=Convert(date,cast( @StartDate as date),103) AND CAST(PHM.TRNSCTN_DATE AS DATE)<=Convert(date,cast( @EndDate as date),103)
	AND PHM.IsActive=1
	GROUP BY PatientCategoryName)
	select PatientCategoryName,round(sum(sumVal),0) sumVal from sumValData group by PatientCategoryName
	end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGoodReceiptDetailList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Tabish>
-- Create date: <Create Date,,>
-- Description:	<[Good Receipt Detail List Report,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodReceiptDetail]
--@GRN as varchar(50)
AS
BEGIN
SELECT a.TRNSCTN_ID as [Goods_Receipt_No.],a.TRNSCTN_DATE as [Receipt_Date],a.PurchaseOrderId as [PO_Number],
b.SupplierShortName,c.ItemCode,d.ItemName,c.RecievedQty as [Received_Quantity],c.BonusQty as [BonusQty_Quantity],
c.ItemRate as [ItemRatee],c.TotalAmount as[Item_Amount] ,c.SaleTax as [Item_Tax],
a.ChallanNo as [InvoiceNumber],a.ChallanDate as [InvoiceDate],e.TRNSCTN_DATE as [PoDate],c.DiscountValue,c.AfterDiscountAmount
FROM SCPTnGoodReceiptNote_M as a 
INNER JOIN SCPStSupplier b on a.SupplierId = b.SupplierId
INNER JOIN SCPTnGoodReceiptNote_D c on a.TRNSCTN_ID = c.PARENT_TRNSCTN_ID
INNER JOIN SCPStItem_M d on c.ItemCode = d.ItemCode
INNER JOIN SCPTnPurchaseOrder_M e on a.PurchaseOrderId = e.TRNSCTN_ID
--WHERE a.TRNSCTN_ID =@GRN

END

















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPGoodsIssuedList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacyIssuance]
@TransactionId varchar(50)
AS
BEGIN

	SET NOCOUNT ON;



		--	SELECT *, (ISSUED_QTY* ITM_RATE) AS ITM_AMOUNT FROM 
		--	(SELECT PHM.ItemCode AS ItemCode, ITM.ItemName AS ITM,DOS.DosageName AS DOSAGE, STK.BatchNo AS BatchNo,
		--	PHM.IssueQty AS ISSUED_QTY,SHLF.ShelfName AS SHLF,
		--	PRIC.SalePrice AS MRP,
		--	 PRIC.CostPrice  AS ITM_RATE
		--	FROM  SCPTnPharmacyIssuance_D PHM
		--	INNER JOIN SCPTnPharmacyIssuance_M PH ON PH.TRNSCTN_ID = PHM.PARENT_TRNSCTN_ID
		--	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PHM.ItemCode 
		--	INNER JOIN SCPTnStock_D STK ON STK.ItemCode = PHM.ItemCode  AND STK.TransactionDocumentId =PHM.PARENT_TRNSCTN_ID
		--	INNER JOIN SCPStDosage DOS ON DOS.DosageId = ITM.DosageFormId
		-- inner join SCPStRate PRIC on PRIC.ItemCode = ITM.ItemCode AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
		--WHERE CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode= ITM.ItemCode )
		--	INNER JOIN SCPStItem_D_Shelf IWS ON IWS.ItemCode = ITM.ItemCode 
		--	AND PH.FromWarehouseId = IWS.WraehouseId
		--	INNER JOIN SCPStShelf SHLF ON SHLF.ShelfId = IWS.ShelfId
		--	WHERE PHM.PARENT_TRNSCTN_ID = @TransactionId AND STK.TransactionType ='STOCKOUT'
		--	)X
			SELECT *, (ISSUED_QTY* ITM_RATE) AS ITM_AMOUNT FROM 
			(
			SELECT PHM.PARENT_TRNSCTN_ID,PHM.ItemCode AS ItemCode, ITM.ItemName AS ITM,DOS.DosageName AS DOSAGE, STK.BatchNo AS BatchNo, GRN.ExpiryDate AS EXPRY,
			STK.StockQuantity AS ISSUED_QTY, CASE WHEN GRN.SalePrice IS NULL THEN PRIC.SalePrice ELSE GRN.SalePrice END AS MRP,
			CASE WHEN GRN.ItemRate IS NULL THEN PRIC.CostPrice ELSE GRN.ItemRate END AS ITM_RATE, SHLF.ShelfName AS SHLF
			FROM  SCPTnPharmacyIssuance_D PHM
			INNER JOIN SCPTnPharmacyIssuance_M PH ON PH.TRNSCTN_ID = PHM.PARENT_TRNSCTN_ID
			INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PHM.ItemCode 
			INNER JOIN SCPTnStock_D STK ON STK.ItemCode = PHM.ItemCode  AND STK.TransactionDocumentId =PHM.PARENT_TRNSCTN_ID AND WraehouseId =10
			INNER JOIN SCPStDosage DOS ON DOS.DosageId = ITM.DosageFormId
		    LEFT OUTER JOIN SCPTnGoodReceiptNote_D GRN ON GRN.BatchNo = STK.BatchNo AND GRN.ItemCode = STK.ItemCode 
			AND GRN.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D WHERE SCPTnPharmacyIssuance_D.ItemCode = PHM.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = STK.BatchNo ORDER BY CreatedDate DESC)
			LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = ITM.ItemCode AND PRIC.FromDate <= STK.CreatedDate and PRIC.ToDate >= STK.CreatedDate
			INNER JOIN SCPStItem_D_Shelf IWS ON IWS.ItemCode = ITM.ItemCode AND PH.FromWarehouseId = IWS.WraehouseId
			--AND IWS.ItemShelfMappingId = (SELECT MAX(ItemShelfMappingId) FROM SCPStItem_D_Shelf 
			--WHERE SCPStItem_D_Shelf.WraehouseId=PH.FromWarehouseId AND SCPStItem_D_Shelf.ItemCode=PHM.ItemCode)
			INNER JOIN SCPStShelf SHLF ON SHLF.ShelfId = IWS.ShelfId
			WHERE PHM.PARENT_TRNSCTN_ID = @TransactionId AND STK.TransactionType ='STOCKOUT'
			)X --order by SHLF

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPHospitalFormulary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptHospitalFormulary_D] --@cls = 47
@Cls as int  ,
@SubCls as int,
@Cat as int,
@SubCat as int
AS

BEGIN
	SET NOCOUNT ON;
 IF(@Cls != 0 AND @SubCls = 0 AND @Cat = 0 AND @SubCat = 0)
	BEGIN
		SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.ClassId =@Cls AND a.IsActive=1
	
END
ELSE IF (@Cls != 0 AND @SubCls != 0 AND @Cat = 0 AND @SubCat = 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode,
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
	   INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND A.SubClassId= @SubCls AND a.IsActive=1
END
ELSE IF (@Cls != 0 AND @SubCls! = 0 AND @Cat != 0 AND @SubCat = 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.CategoryId = @Cat AND a.IsActive=1
END

ELSE IF (@Cls != 0 AND @SubCls != 0 AND @Cat != 0 AND @SubCat != 0)
BEGIN 
SELECT CAST(b.GenericName  AS VARCHAR(50)) AS GenericName,a.GenericId ,CAST(c.DosageName AS VARCHAR(250)) AS DosageName,
		CAST(d.StrengthIdName AS VARCHAR(250)) AS StrengthIdName, a.FormularyId ,CAST(e.FormularyName AS VARCHAR(250)) AS FormularyName
		,CAST(a.ItemName AS VARCHAR(250)) AS ItemName, a.ItemCode, 
		CAST(F.ClassName AS VARCHAR(250)) AS ClassName, 
		CAST(g.SubClassName AS VARCHAR(250)) AS SUBClassName,
		CAST(h.CategoryName AS VARCHAR(250)) AS CategoryName, 
		CAST(i.SubCategoryName AS VARCHAR(250)) AS SBCategoryName
		FROM SCPStItem_M as a 
		INNER JOIN SCPStGeneric b on a.GenericId=b.GenericId
		INNER JOIN SCPStDosage c ON a.DosageFormId=c.DosageId
		INNER JOIN SCPStStrengthId d ON a.StrengthId = d.StrengthIdId
		INNER JOIN SCPStFormulary e ON a.FormularyId = e.FormularyId
		INNER JOIN SCPStClassification f ON a.ClassId= f.ClassId
		INNER JOIN SCPStSubClassification g ON a.SubClassId= g.SubClassId
		INNER JOIN SCPStCategory h ON a.CategoryId = h.CategoryId
		INNER JOIN SCPStSubCategory i ON a.SubCategoryId = i.SubCategoryId
		WHERE a.ItemTypeId = 2 AND a.SubCategoryId  = @SubCat AND a.IsActive=1 
END
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPHospitalFormularySummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptHospitalFormulary_M]
AS
BEGIN
		SELECT FormularyName,COUNT(SCPStItem_M.ItemCode) AS TTL_ITEM,COUNT(SCPTnSale_D.ItemCode) AS SL_ITEM,
	CASE WHEN SCPStFormulary.FormularyId=40 THEN '80 %' WHEN SCPStFormulary.FormularyId=41 THEN '100 %'
	WHEN SCPStFormulary.FormularyId=42 THEN '60 %' ELSE '' END AS STNDRD  FROM SCPStFormulary 
	LEFT OUTER JOIN SCPStItem_M ON SCPStItem_M.FormularyId = SCPStFormulary.FormularyId
	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
	WHERE SCPStItem_M.IsActive=1
	GROUP BY SCPStFormulary.FormularyId,FormularyName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV0009_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPGetReturnToSupplier_D] 
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID,ItemCode,BatchNo ,CurrentStock, ItemRate, ReturnQty, NetAmount
    FROM SCPTnReturnToSupplier_D where PARENT_TRNSCTN_ID=@TransactionId
END 

--SELECT *FROM SCPTnReturnToSupplier_D

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV0009_D2_New]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[Sp_SCPINV0009_D2_New] -- wrong
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID,ItemCode,BatchNo ,CurrentStock, ItemRate, ReturnQty, NetAmount
    FROM SCPTnReturnToSupplier_D where PARENT_TRNSCTN_ID=@TransactionId
END 

--SELECT *FROM SCPTnReturnToSupplier_D

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnStock_D_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockItem]
@WraehouseId as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN  SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	where SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
	ORDER BY ItemName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnStock_D_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemBatchNoes]
@ItemId as varchar(50)	,
@WraehouseId as int
AS
BEGIN
	SELECT distinct I.BatchNo AS BatchNo,I.BatchNo AS BatchNo
    FROM SCPTnStock_M I
    WHERE I.ItemCode=@ItemId and WraehouseId=@WraehouseId
	and I.CurrentStock>0
END


GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPINV003_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIndentsPending]
AS
BEGIN
	
  SELECT SCPTnIndent_M.TRANSCTN_ID,CONVERT(VARCHAR(10), SCPTnIndent_M.TRANSCTN_DT, 105)+' '+CONVERT(VARCHAR(5),SCPTnIndent_M.CreatedDate,108) AS TRANSCTN_DT,
  SCPStDepartment.DepartmentName,CASE WHEN SCPStUser_M.EmployeeCode IS NULL THEN SCPStEmployee.EmployeeName ELSE UserName END AS EmployeeName FROM SCPTnIndent_M
  INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId=SCPTnIndent_M.DepartmentId
  INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnIndent_M.CreatedBy
  LEFT OUTER JOIN SCPStEmployee ON SCPStUser_M.EmployeeCode = SCPStEmployee.EmployeeCode
  WHERE SCPTnIndent_M.IsApprove=1 AND SCPTnIndent_M.TRANSCTN_ID NOT IN(select Distinct IndentId from SCPTnIssuance_M) 
  order by SCPTnIndent_M.TRANSCTN_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV004_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIndentPendingItems]
  @IndNo as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;

 --	SELECT Distinct SCPTnIndent_D.ItemCode, CASE WHEN SCPTnIndent_D.ItemCode=-1 THEN SCPTnIndent_D.ItemName ELSE ITM.ItemName END AS ItemName FROM SCPTnIndent_D
 --   LEFT OUTER JOIN SCPTnIssuance_D ON SCPTnIssuance_D.IndentId = SCPTnIndent_D.PARENT_TRNSCTN_ID
	--INNER JOIN SCPStItem_M ITM ON SCPTnIndent_D.ItemCode = ITM.ItemCode 
	--AND SCPTnIssuance_D.ItemCode = SCPTnIndent_D.ItemCode 
	--WHERE(SCPTnIndent_D.RequestedQty-ISNULL(SCPTnIssuance_D.IssuedQty,0))>0 AND 
	--SCPTnIndent_D.PARENT_TRNSCTN_ID = @IndNo

	
	SELECT Distinct SCPTnIndent_D.ItemCode, SCPTnIndent_D.ItemName AS ItemName FROM SCPTnIndent_D
    LEFT OUTER JOIN SCPTnIssuance_D ON SCPTnIssuance_D.IndentId = SCPTnIndent_D.PARENT_TRNSCTN_ID
	WHERE PendingQty>0 AND 
	SCPTnIndent_D.PARENT_TRNSCTN_ID = @IndNo
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV004_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIndentPendingItemDetail] 
@IndNo as varchar(50),
@ItemId as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SCPTnIndent_D.ItemCode,SCPTnIndent_D.ItemName, SCPTnIndent_D.RequestedQty,SCPTnIndent_D.PendingQty AS PENDING_QTY  FROM SCPTnIndent_D
    LEFT OUTER JOIN SCPTnIssuance_D ON SCPTnIssuance_D.IndentId = SCPTnIndent_D.PARENT_TRNSCTN_ID
	AND SCPTnIssuance_D.ItemCode = SCPTnIndent_D.ItemCode 
	WHERE PendingQty>0 AND 
	SCPTnIndent_D.PARENT_TRNSCTN_ID = @IndNo AND SCPTnIndent_D.ItemCode = @ItemId

	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV004_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateIndentDiscardNo]
AS
BEGIN
	SELECT 'ND-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+
	RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+
	RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRANSCTN_ID
    FROM SCPTnIndentDiscard_M
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











CREATE proc [dbo].[Sp_SCPGetIndent_D]
(
@ParentId varchar(50))
AS
BEGIN
select a.PARENT_TRNSCTN_ID,a.ItemCode,a.RequestedQty,
CASE 
WHEN a.ItemCode = -1
THEN (SELECT SUBSTRING(a.ItemName, 7, 1000))
END AS ITEM,
case when b.IssuedQty is not null then'Completed' else 'Pending'end as StatusQTY 
from SCPTnIndent_D  as a
LEFT OUTER JOIN  SCPTnIssuance_D as b on b.IndentId=a.PARENT_TRNSCTN_ID  and a.ItemCode=b.ItemCode
LEFT OUTER JOIN SCPStItem_M as x on a.ItemCode = x.ItemCode and x.IsActive=1
where a.PARENT_TRNSCTN_ID= @ParentId
END











GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_DEDIT]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE proc [dbo].[Sp_SCPIndent_DEDIT] -- wrong
(
@ParentId bigint)
AS
BEGIN
select a.ItemCode,a.CURR_STOCK,a.RequestedQty
from SCPTnIndent_D as a
where a.PARENT_TRNSCTN_ID=@ParentId
END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_EditStatus]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE proc [dbo].[Sp_SCPIndent_EditStatus] -- wrong
(
@ParentId bigint)
AS
BEGIN
select a.ItemCode,a.CURR_STOCK,a.RequestedQty,d.DIFF_QTY as PendingIssue,case when d.DIFF_QTY=0 then'Completed' else 'Pending'end as StatusQTY 
from SCPTnIndent_D as a 
--left join SCPTnIssuance_M as c on a.PARENT_TRNSCTN_ID=c.IndentId 
left join SCPTnIssuance_D as d on d.IndentId=a.PARENT_TRNSCTN_ID and a.ItemCode=d.ItemCode
where a.PARENT_TRNSCTN_ID=@ParentId
END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateIndentNo]

AS
BEGIN
	SELECT 'IN-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(FB.TRANSCTN_ID)+1 AS VARCHAR(6)),5) as INID
       FROM SCPTnIndent_M FB
	   	   WHERE MONTH(FB.TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(FB.TRANSCTN_DT) = YEAR(getdate())
END







GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIndent_M]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,a.DepartmentId,a.Status as StatusIdt, IsApprove
FROM  SCPTnIndent_M as a
 where a.TRANSCTN_ID=@Trnsctn_ID
END












GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIndentforSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.DepartmentName
FROM  SCPTnIndent_M as a inner join SCPStDepartment as b on a.DepartmentId=b.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or a.DepartmentId like '%'+@Trnsctn_ID+'%' or b.DepartmentName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSCTN_ID DESC
END











GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_SEDIT]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPIndent_SEDIT] --wrong
@Trnsctn_ID as bigint
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,a.WRHOUSE_ID,a.DEP_FRM_ID,a.DEP_TO_ID
FROM  SCPTnIndent_M as a
 where a.TRANSCTN_ID=@Trnsctn_ID
END










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIndent_Sreach]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPIndent_Sreach] --wrong
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.DepartmentName
FROM  SCPTnIndent_M as a inner join SCPStDepartment as b on a.DEP_FRM_ID=b.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or a.DEP_FRM_ID like '%'+@Trnsctn_ID+'%' or b.DepartmentName like '%'+@Trnsctn_ID+'%'
END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE proc [dbo].[Sp_SCPGetIndent]
(
@Indent_Id varchar(50))
AS
BEGIN
select a.PARENT_TRNSCTN_ID,a.ItemCode,a.RequestedQty,c.DepartmentId
from SCPTnIndent_D as a
inner join SCPTnIndent_M as c on c.TRANSCTN_ID=a.PARENT_TRNSCTN_ID
 WHERE a.PARENT_TRNSCTN_ID=@Indent_Id  and a.ItemCode not IN 
  (SELECT distinct b.ItemCode FROM SCPTnIssuance_D as b where a.PARENT_TRNSCTN_ID=b.IndentId)
END










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE proc [dbo].[Sp_SCPGetIssuance]
(
@ParentId varchar(50))
AS
BEGIN
select a.ItemCode,a.DemandQty,a.IssuedQty,a.CurrentStock,a.IndentId as IndentIddet,
b.TRANSCTN_ID,b.DepartmentId,b.TRANSCTN_DT,c.ItemName,b.WarehouseId
from SCPTnIssuance_D as a 
inner join SCPTnIssuance_M as b on b.TRANSCTN_ID=a.PARENT_TRNSCTN_ID
inner join SCPStItem_M as c on c.ItemCode=a.ItemCode and c.IsActive=1
where b.TRANSCTN_ID=@ParentId
END












GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_D6N]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceItemList]
@WraehouseId as int

AS
BEGIN
    SELECT Distinct x.ItemCode, x.ItemName FROM SCPStItem_M x 
	INNER JOIN SCPStItem_D_WraehouseName y ON y.ItemCode = x.ItemCode
	inner join SCPTnStock_M b on b.ItemCode=x.ItemCode and b.WraehouseId=@WraehouseId AND B.CurrentStock > 0
	where x.IsActive=1
END



GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_DN]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO















CREATE proc [dbo].[Sp_SCPGetItemsForIssuance]
(
@Indent_Id varchar(50),@Wid int)
AS
BEGIN

--  SELECT IND.PARENT_TRNSCTN_ID, ITM.ItemCode,ITM.ItemName,IND.RequestedQty,ISNULL(STCK.StockId,0)AS STOCKID ,ISNULL(STCK.ItemBalance,0) AS BALANCE FROM SCPTnIndent_D IND
--INNER JOIN SCPStItem_M ITM ON IND.ItemCode = ITM.ItemCode
--LEFT OUTER JOIN SCPTnStock_D STCK ON STCK.ItemCode = IND.ItemCode AND STCK.WraehouseId =@Wid AND STCK.StockId =  (SELECT MAX(_INV.StockId) FROM SCPTnStock_D _INV WHERE _INV.ItemCode = ITM.ItemCode AND _INV.WraehouseId =STCK.WraehouseId)
--WHERE IND.PARENT_TRNSCTN_ID = @Indent_Id and   IND.ItemCode not IN 
--  (SELECT distinct b.ItemCode FROM SCPTnIssuance_D as b where IND.PARENT_TRNSCTN_ID=b.IndentId)

--SELECT IND.PARENT_TRNSCTN_ID, ITM.ItemCode,ITM.ItemName,IND.RequestedQty, Isnull((SELECT TOP 1 
--STOCK.CurrentStock FROM SCPTnStock_M STOCK WHERE STOCK.WraehouseId = @Wid AND 
--STOCK.ItemCode = ITM.ItemCode AND STOCK.IsActive = 1 ORDER BY STOCK.StockId DESC),0) AS BALANCE 
--FROM SCPTnIndent_D IND INNER JOIN SCPStItem_M ITM ON IND.ItemCode = ITM.ItemCode 
--WHERE IND.PARENT_TRNSCTN_ID = @Indent_Id and IND.ItemCode not IN 
--(SELECT distinct b.ItemCode FROM SCPTnIssuance_D as b where IND.PARENT_TRNSCTN_ID=b.IndentId)


SELECT IND.PARENT_TRNSCTN_ID, IND.ItemCode,
CASE WHEN IND.ItemCode=-1 THEN IND.ItemName ELSE ITM.ItemName END AS ItemName,
IND.PendingQty, Isnull((SELECT TOP 1 
STOCK.CurrentStock
FROM SCPTnStock_M STOCK 
WHERE STOCK.WraehouseId = @Wid  AND 
STOCK.ItemCode = ITM.ItemCode AND STOCK.IsActive = 1 
ORDER BY STOCK.StockId DESC),0) AS BALANCE 
FROM SCPTnIndent_D IND LEFT OUTER JOIN SCPStItem_M ITM ON IND.ItemCode = ITM.ItemCode and ITM.IsActive=1
WHERE IND.PARENT_TRNSCTN_ID = @Indent_Id and IND.ItemCode not IN 
(SELECT distinct b.ItemCode FROM SCPTnIssuance_D as b where IND.PARENT_TRNSCTN_ID=b.IndentId) 
END
















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_F]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE proc [dbo].[Sp_SCPGetIssuance_D]
@id varchar(50)

AS
BEGIN
SELECT C.ItemCode,C.IssuedQty,C.IndentId,C.DemandQty FROM SCPTnIssuance_D C 
inner join SCPTnIssuance_M as a on a.TRANSCTN_ID=C.PARENT_TRNSCTN_ID 
where C.PARENT_TRNSCTN_ID=@id

END










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateIssuanceNo]

AS
BEGIN
	SELECT 'IS-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(FB.TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS PONo
       FROM SCPTnIssuance_M FB
	   	   WHERE MONTH(FB.TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(FB.TRANSCTN_DT) = YEAR(getdate())
END






GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_IndentId]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Sp_SCPGetIndentPendingList] 
 


 

AS
BEGIN

 SET NOCOUNT ON;

 select distinct a.TRANSCTN_ID from SCPTnIndent_M as a 
 inner join SCPTnIndent_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 left join SCPTnIssuance_D as c on a.TRANSCTN_ID=c.IndentId
 where a.IsActive=1 and a.TRANSCTN_ID not in
 (SELECT distinct f.IndentId FROM SCPTnIssuance_D as f where f.ItemCode=b.ItemCode ) 

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_IndentId_P]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Sp_SCPIssuance_IndentId_P] -- wrong
 

 @Dep_ID as INT
 

AS
BEGIN

 SET NOCOUNT ON;

 select distinct a.TRANSCTN_ID from SCPTnIndent_M as a 
 inner join SCPTnIndent_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 left join SCPTnIssuance_D as c on a.TRANSCTN_ID=c.IndentId
 where a.IsActive=1 and a.DEP_FRM_ID=@Dep_ID and a.TRANSCTN_ID not in
 (SELECT distinct f.IndentId FROM SCPTnIssuance_D as f where f.ItemCode=b.ItemCode ) 

END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_ISSFet]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Sp_SCPIssuance_ISSFet] -- wrong
 

 @Dep_ID as INT
 

AS
BEGIN

 SET NOCOUNT ON;

 select distinct a.TRANSCTN_ID from SCPTnIssuance_M as a 
 inner join SCPTnIssuance_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 left join SCPTnGoodReturn_D as c on a.TRANSCTN_ID=c.ISS_ID
 where a.IsActive=1 and a.DepartmentId=@Dep_ID  and a.TRANSCTN_ID not in
 (SELECT distinct f.ISS_ID FROM SCPTnGoodReturn_D as f where f.ItemCode=b.ItemCode ) 
END








GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[Sp_SCPGetIndentListByDept]
 

 @Dep_ID as INT
 

AS
BEGIN

 SET NOCOUNT ON;
  select distinct a.TRANSCTN_ID as IndentID,a.TRANSCTN_ID as IndentName from SCPTnIndent_M as a 
 inner join SCPTnIndent_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 inner join SCPTnApproval as ap on ap.TransactionDocumentId = a.TRANSCTN_ID
  where a.IsActive=1 and a.IsApprove = 1 and a.DepartmentId= @Dep_ID and a.TRANSCTN_ID not in
 (SELECT distinct f.IndentId FROM SCPTnIssuance_D as f where f.ItemCode=b.ItemCode ) and PendingQty>0 and ap.IsApproved != 0
 --select distinct a.TRANSCTN_ID as IndentID,a.TRANSCTN_ID as IndentName from SCPTnIndent_M as a 
 --inner join SCPTnIndent_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 -- where a.IsActive=1 and a.IsReject!=1 and a.DepartmentId=@Dep_ID and a.TRANSCTN_ID not in
 --(SELECT distinct f.IndentId FROM SCPTnIssuance_D as f where f.ItemCode=b.ItemCode ) and PendingQty>0 and a.IsApprove = 1

END










GO


/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.DepartmentName FROM  SCPTnIssuance_M as a 
	inner join SCPStDepartment as b on a.DepartmentId=b.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or  CAST(a.TRANSCTN_DT AS DATE) like '%'+@Trnsctn_ID+'%' 
 or b.DepartmentName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSCTN_ID DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuance_Sreach]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPIssuance_Sreach] -- wrong
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.DepartmentName FROM  SCPTnIssuance_M as a 
inner join SCPStDepartment as b on a.DepartmentId=b.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or  CAST(a.TRANSCTN_DT AS DATE) like '%'+@Trnsctn_ID+'%' 
 or b.DepartmentName like '%'+@Trnsctn_ID+'%'
END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO










CREATE proc [dbo].[Sp_SCPINV007_D1] -- wrong
(
@Indent_Id varchar(50))
AS
BEGIN
select a.PARENT_TRNSCTN_ID,a.ItemCode,a.IssuedQty,a.ITM_RATE
from SCPTnIssuance_D as a
 WHERE a.PARENT_TRNSCTN_ID=@Indent_Id  and a.ItemCode not IN 
  (SELECT distinct b.ItemCode FROM SCPTnGoodReturn_D as b where a.PARENT_TRNSCTN_ID=b.ISS_ID)
END










GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_Fet_IssD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE proc [dbo].[Sp_SCPINV007_Fet_IssD] --- wrong
(
@Indent_Id bigint)
AS
BEGIN
select a.PARENT_TRNSCTN_ID,a.ItemCode,a.IssuedQty,a.ITM_RATE
from SCPTnIssuance_D as a
 WHERE a.PARENT_TRNSCTN_ID=@Indent_Id  and a.ItemCode not IN 
  (SELECT distinct b.ItemCode FROM SCPTnGoodReturn_D as b where a.PARENT_TRNSCTN_ID=b.ISS_ID)
END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateGoodReturnNo]

AS
BEGIN
	SELECT 'RN-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) 
	AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(FB.TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS PONo FROM SCPTnGoodReturn_M FB
	WHERE MONTH(FB.TRANSCTN_DT) = MONTH(getdate()) AND YEAR(FB.TRANSCTN_DT) = YEAR(getdate())
END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[Sp_SCPINV007_L1] -- wrong
 

 @Dep_ID as INT
 

AS
BEGIN

 SET NOCOUNT ON;

 select distinct a.TRANSCTN_ID as ISSID, a.TRANSCTN_ID as ISSName from SCPTnIssuance_M as a 
 inner join SCPTnIssuance_D as b on a.TRANSCTN_ID=b.PARENT_TRNSCTN_ID
 left join SCPTnGoodReturn_D as c on a.TRANSCTN_ID=c.ISS_ID
 where a.IsActive=1 and a.DepartmentId=@Dep_ID  and a.TRANSCTN_ID not in
 (SELECT distinct f.ISS_ID FROM SCPTnGoodReturn_D as f where f.ItemCode=b.ItemCode ) 
END









GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptGoodReturn_D]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnGoodReturn_D.ItemCode,SCPStItem_M.ItemName,ReturnQty,CostPrice,(ReturnQty*CostPrice) AS AMOUNT,ReasonId FROM SCPTnGoodReturn_D
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnGoodReturn_D.ItemCode
	INNER JOIN SCPStReasonId ON SCPStReasonId.ReasonId = SCPTnGoodReturn_D.ReturnReasonIdId
	INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode AND SCPStRate.ItemRateId=(SELECT isnull(Max(ItemRateId),0) 
	FROM SCPStRate WHERE CONVERT(date, getdate()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	WHERE PARENT_TRNSCTN_ID=@TRNSCTN_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_R1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptGoodReturn_M]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT TRANSCTN_DT,DepartmentName,WraehouseName FROM SCPTnGoodReturn_M
	INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId = SCPTnGoodReturn_M.DepartmentId
	INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId=SCPTnGoodReturn_M.WarehouseId
	WHERE TRANSCTN_ID=@TRNSCTN_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE proc [dbo].[Sp_SCPGetGoodReturn]
(
@ParentId varchar(50))
AS
BEGIN
select a.ItemCode,a.ReturnQty,a.PARENT_TRNSCTN_ID,c.TRANSCTN_DT,c.WarehouseId,b.ItemName,a.CurrentStock, C.DepartmentId, D.DepartmentName,A.ReturnReasonIdId
from SCPTnGoodReturn_D as a 
inner join SCPStItem_M as b on b.ItemCode=a.ItemCode
inner join SCPTnGoodReturn_M as c on a.PARENT_TRNSCTN_ID=c.TRANSCTN_ID
INNER JOIN SCPStDepartment AS D ON D.DepartmentId = C.DepartmentId
where a.PARENT_TRNSCTN_ID=@ParentId
END












GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPINV007_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodReturnForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT a.TRANSCTN_ID, a.TRANSCTN_DT,b.WraehouseName,b.WraehouseId, DepartmentId, DepartmentName
FROM  SCPTnGoodReturn_M as a 
inner join SCPStWraehouse as b on b.WraehouseId=a.WarehouseId
INNER JOIN SCPStDepartment ON SCPStDepartment.DepartmentId = A.DepartmentId
 where a.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or  CAST(a.TRANSCTN_DT AS DATE) like '%'+@Trnsctn_ID+'%' 
 or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSCTN_ID DESC
END












GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDiscard_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[Sp_SCPGetItemDiscard]
(
@ParentId varchar(50))
AS
BEGIN
select a.ItemCode,a.BatchNo,a.ExpiryDate,a.ItemRate,a.Quantity,a.CurrentStock,a.Amount,b.TRANSC_ID,b.TRANSC_DT,
b.DIscardType,c.ItemName,b.WraehouseId,b.ItemTypeId, isnull(a.DiscardReasonId,0) as DiscardReasonId
from SCPTnItemDiscard_D as a 
inner join SCPTnItemDiscard_M as b on b.TRANSC_ID=a.PARENT_TRANS_ID
inner join SCPStItem_M as c on c.ItemCode=a.ItemCode and c.IsActive=1
where b.TRANSC_ID=@ParentId
END













GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDiscard_D5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[Sp_SCPItemDetailForDiscard] 
(
@ITEM_CODE varchar(50),
@BatchNo varchar(50),
@Wid int
)
AS
BEGIN

SELECT ISNULL(I.CurrentStock,0) as CurSock,k.ItemRate,k.ExpiryDate as DT FROM SCPTnStock_M I
inner join SCPTnGoodReceiptNote_D as k on k.BatchNo=I.BatchNo and I.ItemCode=k.ItemCode WHERE I.WraehouseId=@Wid 
and I.ItemCode=@ITEM_CODE and I.BatchNo=@BatchNo and I.CurrentStock>0  

END







GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDiscard_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGenerateItemDiscardNo]
AS
BEGIN
SELECT 'IE-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+
RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+
RIGHT('0000'+CAST(COUNT(ID.TRANSC_ID)+1 AS VARCHAR(6)),5) AS TRANSC_ID
FROM SCPTnItemDiscard_M ID

END
GO



/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDiscard_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[Sp_SCPGetItemForDiscard]
(
@name varchar(50),
@Warehoouse int
)

AS
BEGIN
select p.ItemCode,isnull(pd.CostPrice,0) as COST_PR,isnull(i.CurrentStock,0) as CurrentStock from SCPStItem_M P 
left outer join SCPStRate pd on pd.ItemCode=p.ItemCode 
and pd.ItemRateId=(select max(x.ItemRateId) from SCPStRate x where x.ItemCode=pd.ItemCode) 
left outer join SCPTnStock_M i on i.ItemCode=p.ItemCode 
and i.ID=(select max(x.ID) from SCPTnStock_M x where x.ItemCode=i.ItemCode and x.WraehouseId=@Warehoouse)
where P.ItemCode=@name 

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDiscard_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO











-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDiscardForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
SELECT a.TRANSC_ID, a.TRANSC_DT,b.WraehouseName
FROM  SCPTnItemDiscard_M as a inner join SCPStWraehouse as b on a.WraehouseId=b.WraehouseId
 where a.TRANSC_ID LIKE '%'+@Trnsctn_ID+'%' or a.TRANSC_DT  like '%'+@Trnsctn_ID+'%' 
 or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 ORDER BY A.TRANSC_ID DESC
END












GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemForReturnToSupplier]
@ItemId as varchar(50),
@BatchNo as varchar(50),
@WraehouseId as int
AS
BEGIN
	SELECT C.CurrentStock as ItemBalance,b.ItemRate FROM SCPTnStock_M C
inner join SCPTnPurchaseOrder_D b on b.ItemCode=C.ItemCode
WHERE C.BatchNo = @BatchNo AND C.WraehouseId = @WraehouseId AND b.ItemCode = @ItemId
--ORDER BY C.StockId DESC

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToSupplier_D] 
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID,ItemCode,BatchNo ,CurrentStock, ItemRate, ReturnQty, NetAmount
    FROM SCPTnReturnToSupplier_D where PARENT_TRNSCTN_ID=@TransactionId
END 

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_D2_4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDetailForReturnToSupplier]
@ItemId as varchar(50),
@BatchNo as varchar(50),
@WraehouseId as int
AS
BEGIN
	SELECT TOP 1  C.CurrentStock as ItemBalance,
	CASE WHEN b.ItemRate IS NULL THEN PRIC.CostPrice ELSE b.ItemRate END AS ItemRate FROM SCPTnStock_M C
    LEFT OUTER  JOIN SCPTnGoodReceiptNote_D b on b.ItemCode=C.ItemCode and b.BatchNo=c.BatchNo
	AND b.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
	WHERE SCPTnGoodReceiptNote_D.ItemCode = C.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = C.BatchNo)
    LEFT OUTER JOIN SCPStRate PRIC on PRIC.ItemCode = C.ItemCode 
	AND ItemRateId=(select isnull(max(ItemRateId),0) from SCPStRate 
    WHERE CONVERT(date,c.CreatedDate) between FromDate and ToDate and SCPStRate.ItemCode= c.ItemCode )
	WHERE C.BatchNo = @BatchNo AND C.WraehouseId = @WraehouseId AND C.ItemCode = @ItemId
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_D3]    Script Date: 1/24/2020 1:30:11 PM ******/

/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_ExpireItems]    Script Date: 1/24/2020 1:30:11 PM ******/

/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGenerateReturnToSupplierNo]

AS
BEGIN
	SELECT 'RS-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(ReturnToSupplierId)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnReturnToSupplier_M

END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_ItemList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchasedItemsForReturnToSupplier]
@WraehouseId as int,
@SupplierID as int
AS
BEGIN
	SELECT Distinct SCPStItem_M.ItemCode, SCPStItem_M.ItemName FROM SCPStItem_M 
	INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_M.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	INNER JOIN SCPStItem_D_Supplier ON SCPStItem_M.ItemCode = SCPStItem_D_Supplier.ItemCode
	--INNER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_D_WraehouseName.ItemCode 
	--INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_M.GoodReceiptNoteId = SCPTnGoodReceiptNote_D.GoodReceiptNoteId 
	--AND SCPTnGoodReceiptNote_M.SupplierId=SCPStItem_D_Supplier.SupplierId AND SCPTnGoodReceiptNote_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId = SCPStItem_D_WraehouseName.WraehouseId
	WHERE SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId AND SCPStItem_D_Supplier.SupplierId =@SupplierID
	AND SCPStItem_M.IsActive=1
	GROUP BY SCPStItem_M.ItemCode, SCPStItem_M.ItemName
	HAVING SUM(CurrentStock)>0 order by ItemName

END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_Search]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish Tahir>
-- Create date: <Create 19-2-2018,,>
-- Description:	<Search fro,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToSupplierForSearch] 
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnReturnToSupplier_M.TRNSCTN_ID, SCPTnReturnToSupplier_M.TRNSCTN_DATE, 
	SCPStWraehouse.WraehouseName,SCPTnReturnToSupplier_M.DatePassCode as GatePassCode,SCPStSupplier.SupplierShortName
	FROM SCPTnReturnToSupplier_M 
	INNER JOIN SCPStWraehouse ON SCPTnReturnToSupplier_M.WraehouseId = SCPStWraehouse.WraehouseId
	INNER JOIN SCPStSupplier ON SCPTnReturnToSupplier_M.SupplierId = SCPStSupplier.SupplierId
	where SCPTnReturnToSupplier_M.TRNSCTN_ID like '%'+@SearchID+'%'
	ORDER BY SCPTnReturnToSupplier_M.TRNSCTN_ID DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnToSupplier_SearchFilling]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToSupplier_M]
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID, TRNSCTN_DATE, WraehouseId ,DatePassCode as GatePassCode,SupplierId,IsApproved
    FROM SCPTnReturnToSupplier_M where TRNSCTN_ID=@TransactionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockTaking_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTaking_M]
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID, TRNSCTN_DATE, WraehouseId
    FROM SCPTnStockTaking_M where TRNSCTN_ID=@TransactionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockTaking_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateStockTakingNo]

AS
BEGIN
	SELECT 'ST-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnStockTaking_M
	WHERE MONTH(TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(TRNSCTN_DATE) = YEAR(getdate())

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockTaking_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTakingForSearch]
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnStockTaking_M.StockTakingId, SCPTnStockTaking_M.TRNSCTN_DATE, SCPStWraehouse.WraehouseName
FROM SCPTnStockTaking_M INNER JOIN SCPStWraehouse ON SCPTnStockTaking_M.WraehouseId = SCPStWraehouse.WraehouseId
where SCPTnStockTaking_M.StockTakingId like '%'+@SearchID+'%'
ORDER BY SCPTnStockTaking_M.StockTakingId DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAdjustment_M]
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID, TRNSCTN_DATE, WraehouseId
    FROM SCPTnAdjustment_M where TRNSCTN_ID=@TransactionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAdjustment_D] 
@TransactionId as varchar(50)
AS
BEGIN
	SELECT TRNSCTN_ID,ItemCode,BatchNo ,CurrentStock, StockType, ItemPackingQuantity, ItemBalance,ItemRate
    FROM SCPTnAdjustment_D where PARENT_TRNSCTN_ID=@TransactionId
END 

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPgenerateAdjustmentNo]

AS
BEGIN
	SELECT 'AD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnAdjustment_M

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDetailForAdjustment]
@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT,
	@BatchNo AS VARCHAR(50)
AS
BEGIN
	 SELECT STOCK.CurrentStock ,CASE WHEN PRC.ItemRate IS NULL 
    THEN PRIC.CostPrice ELSE PRC.ItemRate END AS SalePrice  FROM SCPTnStock_M STOCK
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = STOCK.ItemCode AND PRC.BatchNo=STOCK.BatchNo 
    LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = STOCK.ItemCode AND PRIC.FromDate <= STOCK.CreatedDate and PRIC.ToDate >= STOCK.CreatedDate
	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = @ItemCode
	AND STOCK.BatchNo = @BatchNo AND STOCK.IsActive = 1 AND STOCK.CurrentStock != 0 
	ORDER BY STOCK.StockId DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptAdjustment_D]
@TRNSCT_ID AS VARCHAR(50)
AS
BEGIN

 -- SELECT TMP.ItemCode,ItemName,TMP.BatchNo,SUM(ADJSTD_QTY) AS ADJSTD_QTY,ItemRate,(SUM(ADJSTD_QTY)*ItemRate) AS AMOUNTT FROM
 -- (
	--SELECT SCPTnAdjustment_D.PARENT_TRNSCTN_ID,SCPTnAdjustment_D.ItemCode,SCPStItem_M.ItemName,SCPTnAdjustment_D.BatchNo,
	--CASE WHEN SCPTnAdjustment_D.StockType=2 THEN CAST('-'+CAST(SCPTnAdjustment_D.ItemPackingQuantity AS varchar(50)) AS int) 
	--ELSE SCPTnAdjustment_D.ItemPackingQuantity END AS ADJSTD_QTY,ItemRate AS ItemRate FROM SCPTnAdjustment_D
	--INNER JOIN SCPTnAdjustment_M M ON M.TRNSCTN_ID=PARENT_TRNSCTN_ID
	--INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnAdjustment_D.ItemCode 
	--WHERE SCPTnAdjustment_D.PARENT_TRNSCTN_ID=@TRNSCT_ID
 -- )TMP
 --  LEFT OUTER JOIN SCPTnStock_D ON SCPTnStock_D.ItemCode = TMP.ItemCode 
 --  AND TransactionDocumentId = PARENT_TRNSCTN_ID AND TMP.BatchNo = SCPTnStock_D.BatchNo
 --  GROUP BY TMP.ItemCode,ItemName,TMP.BatchNo,ItemRate

  SELECT PARENT_TRNSCTN_ID,TMP.ItemCode,ItemName,TMP.BatchNo,
  SUM(ADJSTD_QTY) AS ADJSTD_QTY,ItemRate,(SUM(ADJSTD_QTY)*ItemRate) AS AMOUNTT,
  CASE WHEN ItemBalance IS NULL THEN 'NOT ADJUSTED' ELSE 'ADJUSTED' END AS ADJ_Status FROM
  (
	SELECT SCPTnAdjustment_D.PARENT_TRNSCTN_ID,SCPTnAdjustment_D.ItemCode,SCPStItem_M.ItemName,SCPTnAdjustment_D.BatchNo,
	CASE WHEN SCPTnAdjustment_D.StockType=2 THEN CAST('-'+CAST(SCPTnAdjustment_D.ItemPackingQuantity AS varchar(50)) AS int) 
	ELSE SCPTnAdjustment_D.ItemPackingQuantity END AS ADJSTD_QTY,ItemRate AS ItemRate 
	--CASE WHEN PRC.ItemRate IS NULL THEN PRIC.CostPrice ELSE PRC.ItemRate END AS ItemRate 
	FROM SCPTnAdjustment_D
	INNER JOIN SCPTnAdjustment_M M ON M.TRNSCTN_ID=PARENT_TRNSCTN_ID
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnAdjustment_D.ItemCode 
	--INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode = SCPStItem_M.ItemCode AND STOCK.WraehouseId = m.WraehouseId and STOCK.BatchNo=SCPTnAdjustment_D.BatchNo
	--LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = STOCK.ItemCode AND PRC.BatchNo=STOCK.BatchNo 
   -- LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = STOCK.ItemCode AND PRIC.FromDate <= STOCK.CreatedDate and PRIC.ToDate >= STOCK.CreatedDate
	WHERE SCPTnAdjustment_D.PARENT_TRNSCTN_ID=@TRNSCT_ID
   )TMP
   LEFT OUTER JOIN SCPTnStock_D ON SCPTnStock_D.ItemCode = TMP.ItemCode 
   AND TransactionDocumentId = PARENT_TRNSCTN_ID AND TMP.BatchNo = SCPTnStock_D.BatchNo
   GROUP BY PARENT_TRNSCTN_ID,TMP.ItemCode,ItemName,TMP.BatchNo,ItemRate,ItemBalance
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_R2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptAdjustment_M]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPStWraehouse.WraehouseName,CONVERT(VARCHAR(10), SCPTnAdjustment_M.TRNSCTN_DATE, 105) AS TRNSCTN_DATE,SCPStUser_M.UserName,
    (CONVERT(VARCHAR(10), SCPTnAdjustment_M.CreatedDate, 105)+' '+ CONVERT(VARCHAR(5),SCPTnAdjustment_M.CreatedDate,108)) AS CRTD_DATE FROM SCPTnAdjustment_M
    INNER JOIN SCPStWraehouse ON SCPTnAdjustment_M.WraehouseId = SCPStWraehouse.WraehouseId
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnAdjustment_M.CreatedBy WHERE TRNSCTN_ID=@TRNSCTN_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPAdjustment_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPAdjustmentForSearch]
@SearchID as varchar(50)
AS
BEGIN
	SELECT SCPTnAdjustment_M.TRNSCTN_ID, SCPTnAdjustment_M.TRNSCTN_DATE, SCPStWraehouse.WraehouseName
FROM SCPTnAdjustment_M INNER JOIN SCPStWraehouse ON SCPTnAdjustment_M.WraehouseId = SCPStWraehouse.WraehouseId
where SCPTnAdjustment_M.TRNSCTN_ID like '%'+@SearchID+'%'
ORDER BY SCPTnAdjustment_M.TRNSCTN_ID DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnInventoryValuation_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptInventoryValuationSummary] 
@WraehouseId as int
AS
BEGIN
	 SELECT Distinct MIN_VLTN,MAX_VLTN,AVG_VLTN,CRNT_VLTN,REPLACE(CONVERT(CHAR(9), DATA_DT, 6),' ','-') as DATA_DT
	 FROM SCPTnInventoryValuation where WraehouseId=@WraehouseId and DATA_DT BETWEEN DATEADD(DAY,-30,GETDATE()) AND GETDATE()
	 ORDER BY DATA_DT
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPIssuence]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetItemIssued]
@IssuenceId varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

		SELECT ISS.ItemCode AS ItemCode, ITM.ItemName AS ITM,ISS.IssuedQty AS ISSUED_QTY,
		SHLF.ShelfName AS SHLF
			FROM  SCPTnIssuance_D ISS
			 INNER JOIN SCPTnIssuance_M ON ISS.PARENT_TRNSCTN_ID = SCPTnIssuance_M.TRANSCTN_ID
			INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = ISS.ItemCode 
			INNER JOIN SCPStItem_D_Shelf IWS ON IWS.ItemCode = ITM.ItemCode
			AND IWS.WraehouseId = SCPTnIssuance_M.WarehouseId
			INNER JOIN SCPStShelf SHLF ON SHLF.ShelfId = IWS.ShelfId
			WHERE ISS.PARENT_TRNSCTN_ID = @IssuenceId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemCriticalOnZero]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptItemCriticalOnZero] 
@WraehouseName as INT
AS
BEGIN
	
	SET NOCOUNT ON;
   
SELECT  ItemCode, ItemName,CurrentStock,isnull(DAYS_DIF,0) as DAYS_DIF,CONVERT(VARCHAR(10),PO_DATE,105) AS PO_DATE,
CONVERT(VARCHAR(10),GRN_DATE,105) AS GRN_DATE,PO.SupplierLongName AS PO_SUP, GRN.SupplierLongName  AS GRN_SUP FROM (
SELECT ItemCode,ItemName,CurrentStock,DATEDIFF(DAY,STOCK_DT,GETDATE()) AS DAYS_DIF,PO_DATE,GRN_DATE,(SELECT SCPTnPurchaseOrder_M.SupplierId FROM SCPTnPurchaseOrder_M 
WHERE SCPTnPurchaseOrder_M.TRNSCTN_ID = PurchaseOrderId) AS PO_SUP, 
 (SELECT SCPTnGoodReceiptNote_M.SupplierId FROM SCPTnGoodReceiptNote_M WHERE SCPTnGoodReceiptNote_M.GoodReceiptNoteId = GoodReceiptNo) AS GRN_SUP FROM (
SELECT SCPStItem_M.ItemCode AS ItemCode,SCPStItem_M.ItemName AS ItemName,SUM(CurrentStock) AS CurrentStock,
CASE WHEN MAX(SCPTnStock_M.EditedDate) IS NULL THEN MAX(SCPTnStock_M.CreatedDate) ELSE MAX(SCPTnStock_M.EditedDate) END AS STOCK_DT,
(SELECT TOP 1 PRCD.PARENT_TRNSCTN_ID FROM SCPTnPurchaseOrder_D PRCD WHERE PRCD.ItemCode=SCPStItem_M.ItemCode ORDER BY PRCD.CreatedDate DESC) AS PurchaseOrderId,
(SELECT TOP 1 PRCD.CreatedDate FROM SCPTnPurchaseOrder_D PRCD WHERE PRCD.ItemCode=SCPStItem_M.ItemCode ORDER BY PRCD.CreatedDate DESC) AS PO_DATE,
(SELECT TOP 1 GRND.CreatedDate FROM SCPTnGoodReceiptNote_D GRND WHERE GRND.ItemCode=SCPStItem_M.ItemCode ORDER BY GRND.CreatedDate DESC) AS GRN_DATE,
(SELECT TOP 1 GRND.PARENT_TRNSCTN_ID FROM SCPTnGoodReceiptNote_D GRND WHERE GRND.ItemCode=SCPStItem_M.ItemCode ORDER BY GRND.CreatedDate DESC) AS GoodReceiptNo
FROM SCPStItem_M INNER JOIN SCPTnStock_M ON SCPStItem_M.ItemCode = SCPTnStock_M.ItemCode 
WHERE SCPStItem_M.IsActive=1 AND FormularyId!=0 AND SCPTnStock_M.WraehouseId=@WraehouseName
GROUP BY SCPStItem_M.ItemCode,SCPStItem_M.ItemName
HAVING  SUM(CurrentStock) = 0
)X 
)Y LEFT OUTER JOIN SCPStSupplier PO ON PO.SupplierId = PO_SUP 
LEFT OUTER  JOIN SCPStSupplier GRN ON  GRN.SupplierId = GRN_SUP
ORDER BY DAYS_DIF
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDeadStock]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemStock]
	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	 
	SELECT ISNULL(Sum(STOCK.CurrentStock),0) as CurrentStock FROM SCPTnStock_M STOCK
	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = @ItemCode AND STOCK.IsActive = 1 --AND STOCK.CurrentStock != 0
    
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemDemand]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetItemDemand]
@IndentId varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
SELECT PARENT_TRNSCTN_ID, IND.ItemCode, ITM.ItemName, IND.DemandQty, IND.CreatedDate,USR.UserName, ItemBalance,
CONVERT(VARCHAR(125),DOS.DosageName) AS DOS_NM
 FROM SCPTnDemand_D IND
INNER JOIN SCPStUser_M USR ON USR.UserId = IND.CreatedBy
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = IND.ItemCode
INNER JOIN SCPStDosage DOS ON ITM.DosageFormId = DOS.DosageId
 WHERE PARENT_TRNSCTN_ID = @IndentId
 GROUP BY PARENT_TRNSCTN_ID, IND.ItemCode, ITM.ItemName, IND.DemandQty, 
 IND.CreatedBy, IND.CreatedDate,USR.UserName,ItemBalance,  DOS.DosageName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemExistCheck]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPCheckItemExist]
@ItemCode as Varchar(50),
@ItemName as Varchar(50),
@GncId as INT,
@FrmlryID as INT,
@DsgFrmId as INT,
@StrengthIdId as INT,
@UnitId as INT

AS
BEGIN

	 if exists(select * from SCPStItem_M where ItemName=@ItemName and GenericId=@GncId and FormularyId=@FrmlryID 
	 and DosageFormId=@DsgFrmId and StrengthId=@StrengthIdId and ItemUnit=@UnitId and ItemCode!=@ItemCode)
	 begin 
	  select cast(1 as bit) as ExistCheck
	 end
	 else
	  begin 
	  select cast(0 as bit) as ExistCheck
	 end

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemLed]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[Sp_SCPRptItemLedger] 

@FromDate varchar(50),
@ToDate varchar(50),
@WraehouseId int,
@ItemId int
AS
BEGIN
    	declare 
	    @FromDt varchar(50) = @FromDate,
		@ToDt varchar(50)= @ToDate,
		@WraehouseName int=@WraehouseId,
		@ItmId varchar(50)= @ItemId
 
      SET NOCOUNT ON;

	SELECT SCPTnStock_D.ItemCode AS ItemID,SecondTable.OPENINGBAL,ThirdTable.CLOSINGBAL,
	SCPStItem_M.ItemName AS NAME,
	SCPTnStock_D.TransactionDocumentId AS DocId,
	SCPTnStock_D.WraehouseId AS WraehouseName,
	CONVERT(VARCHAR( 10),SCPTnStock_D.CreatedDate,105) AS DateAndTime,
	SCPTnStock_D.CreatedDate AS DATEE,
	SCPTnStock_D.TransactionDocumentId AS DOCtype,
	SCPTnStock_D.CurrentStock AS CS, 
	SCPTnStock_D.ItemBalance AS BAL,
	SCPTnStock_D.BatchNo AS BatchNo,
	CASE WHEN  TransactionType ='STOCKIN' THEN  SCPTnStock_D.ItemPackingQuantity  ELSE 0 END AS QuantityIN,
	CASE WHEN  TransactionType ='STOCKOUT' THEN  SCPTnStock_D.ItemPackingQuantity  ELSE 0 END AS QuantityOUT
	FROM SCPTnStock_D 
	INNER JOIN SCPStItem_M ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode
	CROSS APPLY
	(
			SELECT SUM(CurrentStock) AS OPENINGBAL FROM 
			(
				SELECT BatchNo,CurrentStock,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate) AS RN
				FROM SCPTnStock_D WHERE ItemCode=SCPStItem_M.ItemCode and WraehouseId=@WraehouseName 
				AND CAST(CreatedDate as date) >= CAST(CONVERT(date,@FromDt,103) as date)
			)TMP WHERE RN = 1
		) AS SecondTable
	CROSS APPLY
	(
			SELECT SUM(ItemBalance) AS CLOSINGBAL FROM 
			(
				SELECT BatchNo,ItemBalance,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN
				FROM SCPTnStock_D WHERE ItemCode= SCPStItem_M.ItemCode and WraehouseId=@WraehouseName 
				AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDt,103) as date)
			)TMP WHERE RN = 1
		) AS ThirdTable
    WHERE cast(SCPTnStock_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDt,103) as date) AND
	CAST(CONVERT(date,@ToDt,103) as date) AND
	SCPTnStock_D.ItemCode =@ItmId AND SCPTnStock_D.WraehouseId = @WraehouseName
	ORDER BY SCPTnStock_D.CreatedDate

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemNotIssuedAgainstDemand]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE[dbo].[Sp_SCPRptItemNotIssuedAgainstDemand]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;
SELECT D_D.PARENT_TRNSCTN_ID,
	   CONVERT(VARCHAR(10),D_D.CreatedDate, 105) AS DEMANDDATE,
	   CLS.ClassName AS ClassName,
  CAST((DATEDIFF(HOUR, D_D.CreatedDate, GETDATE()) / 24) AS VARCHAR) AS DAYSS,
    CAST((DATEDIFF(HOUR, D_D.CreatedDate, GETDATE()) % 24) AS VARCHAR) AS HOURSS,
	   D_D.ItemCode,
	   ITM.ItemName,
	   Dose.DosageName AS DoseName,
	   D_D.DemandQty,
	   D_D.PendingQty,
	   ISNULL(I_D.IssueQty,0) AS ISSUEDQTY
 FROM SCPTnDemand_D D_D
 LEFT OUTER JOIN SCPTnPharmacyIssuance_D I_D ON I_D.DemandId = D_D.PARENT_TRNSCTN_ID AND I_D.ItemCode = D_D.ItemCode
 INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = D_D.ItemCode and itm.IsActive=1
 INNER JOIN SCPStClassification AS CLS On CLS.ClassId = ITM.ClassId
 INNER JOIN [SCPStDosage] AS Dose ON Dose.DosageId = ITM.DosageFormId
 WHERE D_D.PendingQty > 0 AND cast(D_D.CreatedDate as date) 
 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)  
 ORDER BY D_D.CreatedDate desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemNotIssuedAgainstDemand(Weekly)]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPItemNotIssuedAgainstDemandWeekly]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

--SELECT DEMANDDATE,SUM(PENDING) AS ITEMNOTISSUED, 
--SUM(LESSTHAN3) AS LESSTHAN3,SUM(BW3TO6) AS BW3TO6, 
--SUM(BW6TO8) AS BW6TO8, SUM(GREATERTHAN8) AS GREATERTHAN8, 
--SUM(NOTTODAY) AS NOTTODAY
--FROM(
--	SELECT  CONVERT(VARCHAR(10),X.DEMANDDATE,105) AS DEMANDDATE ,SUM(X.PENDINGQTY) AS PENDING,
--	CASE WHEN (X.Hours < 3)  THEN (SELECT X.ISSUEDQuantity)END  AS LESSTHAN3  ,
--	CASE WHEN (X.Hours BETWEEN 3 AND 6)  THEN (SELECT X.ISSUEDQuantity)END AS BW3TO6,
--	CASE WHEN (X.Hours BETWEEN 6 AND 8)  THEN (SELECT X.ISSUEDQuantity)END AS BW6TO8,
--	CASE WHEN (X.Hours > 8 )  THEN (SELECT X.ISSUEDQuantity)END AS GREATERTHAN8,
--	CASE WHEN (X.Hours > 24 )  THEN (SELECT X.ISSUEDQuantity)END AS NOTTODAY 
--	FROM(	
--		SELECT D_D.CreatedDate AS DEMANDDATE,
--		D_D.PARENT_TRNSCTN_ID AS DEMANDNO,
--		 D_D.DemandQty AS DEMANDQTY,ITM.ItemName AS ITMNAME ,
--		I_D.CreatedDate, DATEDIFF(HOUR,   D_D.CreatedDate, I_D.CreatedDate) AS  Hours,
--		D_D.PendingQty AS PENDINGQTY,
--		I_D.IssueQty AS ISSUEDQuantity
--		FROM SCPTnDemand_D D_D 
--		LEFT OUTER JOIN SCPTnPharmacyIssuance_D I_D ON I_D.DemandId = D_D.PARENT_TRNSCTN_ID AND I_D.ItemCode = D_D.ItemCode
--		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = D_D.ItemCode
--	)X GROUP BY CONVERT(VARCHAR(10),X.DEMANDDATE,105),ISSUEDQuantity,Hours
--)Y WHERE Y.DEMANDDATE BETWEEN @FromDate AND @ToDate
--	GROUP BY Y.DEMANDDATE


SELECT DEMANDDATE,SUM(DEMANDQuantity) AS DEMANDQuantity, SUM(PENDING) AS ITEMNOTISSUED, 
SUM(LESSTHAN3) AS LESSTHAN3,SUM(BW3TO6) AS BW3TO6, 
SUM(BW6TO8) AS BW6TO8, SUM(GREATERTHAN8) AS GREATERTHAN8, 
SUM(NOTTODAY) AS NOTTODAY
FROM(
	SELECT  CONVERT(VARCHAR(10),X.DEMANDDATE,105) AS DEMANDDATE ,DEMANDDATE AS DATEFORORD,SUM(X.PENDINGQuantity) AS PENDING, SUM(X.DEMANDQTY) AS DEMANDQuantity,
	CASE WHEN (X.Hours < 3)  THEN (SELECT X.ISSUEDQuantity) ELSE 0 END  AS LESSTHAN3  ,
	CASE WHEN (X.Hours BETWEEN 3 AND 6)  THEN (SELECT X.ISSUEDQuantity)ELSE 0 END AS BW3TO6,
	CASE WHEN (X.Hours BETWEEN 6 AND 8)  THEN (SELECT X.ISSUEDQuantity)ELSE 0 END AS BW6TO8,
	CASE WHEN (X.Hours > 8 )  THEN (SELECT X.ISSUEDQuantity) ELSE 0 END AS GREATERTHAN8,
	CASE WHEN (X.Hours > 24 )  THEN (SELECT X.ISSUEDQuantity)ELSE 0 END AS NOTTODAY 
	 --SUM(PENDINGQuantity) AS NOTTODAY 
	FROM(	
		SELECT D_D.CreatedDate AS DEMANDDATE,
		D_D.PARENT_TRNSCTN_ID AS DEMANDNO,
		 D_D.DemandQty AS DEMANDQTY
		 ,ITM.ItemName AS ITMNAME 
		,
		I_D.CreatedDate, DATEDIFF(HOUR,   D_D.CreatedDate, I_D.CreatedDate) AS  Hours,
		D_D.PendingQty AS PENDINGQuantity,
		I_D.IssueQty AS ISSUEDQuantity
		FROM SCPTnDemand_D D_D 
		inner join SCPStItem_M ITM ON ITM.ItemCode = D_D.ItemCode and itm.IsActive=1
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D I_D ON I_D.DemandId = D_D.PARENT_TRNSCTN_ID AND I_D.ItemCode = D_D.ItemCode
		
		WHERE 
	--D_D.PendingQty !=0
		--And  
		cast(D_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
     AND CAST(CONVERT(date,@ToDate,103) as date)
		)X GROUP BY CONVERT(VARCHAR(10),X.DEMANDDATE,105),ISSUEDQuantity,Hours, DEMANDDATE
)Y 
	GROUP BY DATEFORORD,DEMANDDATE
	ORDER BY DATEFORORD
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemOnCriticalsByWraehouseName]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[Sp_SCPGetItemOnCriticalCountByWraehouseName]
@WraehouseId AS INT

AS BEGIN
	
	  SELECT ISNULL(COUNT(ItemCode),0) as ItemsOnCritical FROM   
       (
			SELECT SCPStItem_M.ItemCode,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 13 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS CRT_LVL,
			SUM(STCK.CurrentStock) AS CurrentStock FROM SCPStItem_M
			INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode 
			INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=STCK.WraehouseId
			INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (13)
			AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
			AND CC.WraehouseId =SCPStParLevelAssignment_M.WraehouseId AND CC.IsActive=1) and SCPStItem_M.IsActive=1
			WHERE STCK.WraehouseId=@WraehouseId
			GROUP BY SCPStItem_M.ItemCode,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
       )TMP WHERE CurrentStock<=CRT_LVL and CurrentStock!=0 

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemOnZeroAllWraehouseName]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPGetItemOnZeroCount]

AS BEGIN

SELECT CAST(SUM(POS_ZERO) AS VARCHAR(50))+' %' POS_ZERO,CAST(SUM(MSS_ZERO) AS VARCHAR(50))+' %' MSS_ZERO 
FROM(
	SELECT CASE WHEN WraehouseId=3 THEN ROUND(CAST(SUM(ITEM_ZERO) AS FLOAT)*100/CAST(COUNT(ItemCode) AS FLOAT),0) END AS POS_ZERO,
	CASE WHEN WraehouseId=10 THEN ROUND(CAST(SUM(ITEM_ZERO) AS FLOAT)*100/CAST(COUNT(ItemCode) AS FLOAT),0) END AS MSS_ZERO 
	FROM(
		SELECT INV.WraehouseId,CC.ItemCode,
		CASE WHEN SUM(CurrentStock)>0 THEN 0 ELSE 1 END AS ITEM_ZERO FROM SCPStItem_M CC
		INNER JOIN SCPTnStock_M INV ON INV.ItemCode = CC.ItemCode 
		WHERE CC.IsActive=1 AND CC.FormularyId!=0
		GROUP BY INV.WraehouseId,CC.ItemCode
	)TMP GROUP BY WraehouseId
)TMPP

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemReturnToSupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptReturnToSupplier] 
@TransactionId varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

		SELECT INV.ItemCode AS ItemCode, ITM.ItemName AS ItemName,BatchNo AS BatchNo, ItemRate AS PRICE, ReturnQty AS GP_QTY, 
		NetAmount AS ITM_Amount,ReasonId,CASE WHEN SettlementStatuss=1 THEN 'CREDIT NOTE' 
		WHEN SettlementStatuss=2 THEN 'REPLACEMENT' ELSE 'No Status' END AS SettlementStatuss
		FROM SCPTnReturnToSupplier_D INV 
		INNER JOIN SCPTnReturnToSupplier_M INM ON INV.PARENT_TRNSCTN_ID = INM.TRNSCTN_ID
		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = INV.ItemCode
		INNER JOIN SCPStSupplier ON INM.SupplierId = SCPStSupplier.SupplierId
		INNER JOIN SCPStReasonId ON SCPStReasonId.ReasonId = INV.ReturnReasonIdId
		WHERE INM.TRNSCTN_ID = @TransactionId 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsDeadOnZero]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemDeadOnZeroCount] 
@WraehouseName as int
AS
BEGIN   SELECT 0 as ItemsonZero
		--SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsonZero  FROM 
		--(
		--SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		--left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		--where SCPStItem_M.IsActive=1 AND FormularyId!=0
		--GROUP BY SCPStItem_M.ItemCode,ItemName
		--)TMP
		--WHERE ItemCode IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsOnCritical]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsOnCriticalCount] 
@WraehouseName as int
AS
BEGIN
	
   SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsOnCritical FROM   
          (
              SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 13 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS CRT_LVL,

              SUM(STCK.CurrentStock) AS CurrentStock FROM SCPStItem_M
          
		      INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName

              INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId= @WraehouseName

              INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (13)

              AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 

              AND CC.WraehouseId= @WraehouseName AND CC.IsActive=1) and SCPStItem_M.IsActive=1

              GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
       )TMP

       GROUP BY ItemCode,ItemName,CurrentStock,CRT_LVL HAVING CurrentStock<=SUM(CRT_LVL) and CurrentStock!=0 


END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsOnCritical_Dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,MOIZ_HUSSAIN>
-- Create date: <Create Date, 9/16/2019 10:12:22 AM,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsOnCriticalCountForDashboard] 
@WraehouseName as int

AS
BEGIN

    declare @Items_Critical as decimal,@Items_Addition as decimal

	select @Items_Critical =ItemsOnCritical 
	from (
		SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsOnCritical FROM   
          (
              SELECT SCPStItem_M.ItemCode,ItemName,
			  CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 13 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS CRT_LVL,
			  
              SUM(STCK.CurrentStock) AS CurrentStock FROM SCPStItem_M
          
		      INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId = @WraehouseName 

              INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId =  @WraehouseName

              INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (13)

              AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 

              AND CC.WraehouseId = @WraehouseName
			  AND CC.IsActive=1) and SCPStItem_M.IsActive=1

              GROUP BY SCPStItem_M.ItemCode,ItemName,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
       )TMP
		GROUP BY ItemCode,ItemName,CurrentStock,CRT_LVL HAVING CurrentStock<=SUM(CRT_LVL) and CurrentStock!=0 
	)trm;

	Select  @Items_Addition = COUNT(ItemCode) from SCPStItem_M where IsActive = 1 ;
	Select convert(varchar,@Items_Critical) as ItemsOnCritical,format((@Items_Critical/@Items_Addition),'###.##%') as percentage;

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsOnZero]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemsOnZeroCount] 
@WraehouseName as int
AS
BEGIN      
		SELECT distinct COUNT(*) OVER (PARTITION BY 1) as ItemsonZero  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP WHERE CurrentStock=0
		--WHERE ItemCode NOT IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsOnZero_Dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPGetItemsOnZeroCountForDashboard] 
@WraehouseName as int
AS
BEGIN     

declare @items_zero as int ,@item_zero_percentage as decimal ,@item_total as decimal
		SELECT  distinct @items_zero = COUNT(*) OVER (PARTITION BY 1)  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP WHERE CurrentStock=0

		SELECT  distinct @item_total = COUNT(*) OVER (PARTITION BY 1)  FROM 
		(
		SELECT SCPStItem_M.ItemCode,ItemName,isnull(SUM(STCK.CurrentStock),0) AS CurrentStock FROM SCPStItem_M
		left  JOIN SCPTnStock_M STCK ON STCK.ItemCode=SCPStItem_M.ItemCode AND STCK.WraehouseId= @WraehouseName
		where SCPStItem_M.IsActive=1 AND FormularyId!=0 
		GROUP BY SCPStItem_M.ItemCode,ItemName
		)TMP 



		Select convert(varchar(10),@items_zero) as item_zero , format(@items_zero/@item_total,'##.##%') as percentage
		--WHERE ItemCode NOT IN(
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--   	UNION ALL
		--	SELECT ItemCode FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)
		--GROUP BY ItemCode,ItemName,CurrentStock HAVING CurrentStock=0  ---CostPrice

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemsTotalCount]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[Sp_SCPGetTotalItemsCount] 

AS
BEGIN
	
	  select Count(ItemCode) from SCPStItem_M
	  where IsActive = 1

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPItemSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[Sp_SCPRptItemSummary]
@FromDate as varchar(50),
@ToDate as varchar(50),
@WraehouseName int
AS
BEGIN

	SET NOCOUNT ON;
	
--SELECT SCPTnStock_D.ItemCode AS ItemID, SCPStItem_M.ItemName,
--CASE WHEN  TransactionType ='STOCKIN' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityIN,
--CASE WHEN  TransactionType ='STOCKOUT' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityOUT,
-- SUM(SCPTnStock_D.ItemBalance) AS BALANCE,SUM(SCPTnStock_D.CurrentStock) AS OPENINGBALANCE
--FROM SCPTnStock_D INNER JOIN SCPStItem_M ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode
--where Convert(varchar(10),CONVERT(date,SCPTnStock_D.CreatedDate,106),103) BETWEEN @FromDate AND @ToDate AND WraehouseId = @WraehouseName
--GROUP BY SCPTnStock_D.ItemCode,TransactionType,SCPStItem_M.ItemName

--SELECT *,((OPENINGBAL + QuantityIN)-QuantityOUT) AS BAL FROM (
--SELECT DISTINCT ItemID,NAME, SUM(QuantityIN) AS QuantityIN,SUM(QuantityOUT)AS QuantityOUT ,
--ISNULL((
--SELECT SUM(ItemBalance) FROM (
--SELECT ItemCode,BatchNo,ItemBalance FROM (
--  SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate) AS RN
--   FROM SCPTnStock_D WHERE ItemCode=SCPTnStock_D.ItemCode and WraehouseId=@WraehouseName
--   AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@FromDate,103) as date)
--  )TMP WHERE RN = 1 AND ItemCode = X.ItemID
--)TMP1),0) AS OPENINGBAL FROM (
--SELECT SCPTnStock_D.ItemCode AS ItemID, SCPStItem_M.ItemName AS NAME, 
----(SELECT SUM(SCPTnStock_D.ItemPackingQuantity) WHERE TransactionType ='STOCKIN' )AS QuantityIN,
----(SELECT SUM(SCPTnStock_D.ItemPackingQuantity)  WHERE TransactionType ='STOCKOUT') AS QuantityOUT
--CASE WHEN  TransactionType ='STOCKIN' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityIN,
-- CASE WHEN TransactionType ='STOCKOUT' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityOUT
--FROM SCPTnStock_D INNER JOIN SCPStItem_M ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode
--where cast(SCPTnStock_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
--AND CAST(CONVERT(date,@ToDate,103) as date) AND WraehouseId = @WraehouseName
--GROUP BY SCPTnStock_D.ItemCode,SCPStItem_M.ItemName,TransactionType
--)x WHERE  ItemID = ItemID GROUP BY ItemID, NAME
--)Y 

SELECT * FROM (
SELECT DISTINCT ItemID,NAME, SUM(QuantityIN) AS QuantityIN,SUM(QuantityOUT)AS QuantityOUT,OPENINGBAL,CLOSININGBAL AS BAL FROM (
    SELECT SCPTnStock_D.ItemCode AS ItemID, SCPStItem_M.ItemName AS NAME, 
	CASE WHEN  TransactionType ='STOCKIN' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityIN,
	CASE WHEN TransactionType ='STOCKOUT' THEN  (select SUM(SCPTnStock_D.ItemPackingQuantity)) ELSE 0 END AS QuantityOUT,
	ISNULL((
	SELECT SUM(ItemBalance) FROM (
	SELECT ItemCode,BatchNo,ItemBalance FROM (
	  SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate) AS RN
	   FROM SCPTnStock_D INV WHERE INV.ItemCode=SCPTnStock_D.ItemCode and INV.WraehouseId=@WraehouseName
	   AND CAST(INV.CreatedDate as date) <= CAST(CONVERT(date,@FromDate,103) as date)
	  )TMP WHERE RN = 1 
	)TMP1),0) AS OPENINGBAL,
	ISNULL((
	SELECT SUM(ItemBalance) FROM (
	SELECT ItemCode,BatchNo,ItemBalance FROM (
	  SELECT *,ROW_NUMBER() OVER (PARTITION BY BatchNo ORDER BY CreatedDate DESC) AS RN
	   FROM SCPTnStock_D INV WHERE INV.ItemCode=SCPTnStock_D.ItemCode and INV.WraehouseId=@WraehouseName
	   AND CAST(CreatedDate as date) <= CAST(CONVERT(date,@ToDate,103) as date)
	  )TMP WHERE RN = 1 
	)TMP1),0) AS CLOSININGBAL
	FROM SCPTnStock_D INNER JOIN SCPStItem_M ON SCPTnStock_D.ItemCode = SCPStItem_M.ItemCode
	where cast(SCPTnStock_D.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND WraehouseId = @WraehouseName
	GROUP BY SCPTnStock_D.ItemCode,SCPStItem_M.ItemName,TransactionType
  )x WHERE  ItemID = ItemID GROUP BY ItemID, NAME,OPENINGBAL,CLOSININGBAL
)Y 

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPLpItemProfit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetLpItemProfit]

AS BEGIN

--SELECT CAST(SUM(CASE WHEN TMPPP.ClassId=1 THEN ROUND((SALE-COGS)*100/SALE,1) END) AS VARCHAR(50)) +' %' AS Medicnes,
--CAST(SUM(CASE WHEN TMPPP.ClassId=2 THEN ROUND((SALE-COGS)*100/SALE,1) END) AS VARCHAR(50)) +' %' AS Surgical  FROM

SELECT CASE WHEN FormularyId=0 THEN 'Nom-Formulary' ELSE 'Formulary' END AS LP_TYPE,SUM(ROUND((SALE-COGS)*100/SALE,1)) AS VALUE FROM
(
SELECT FormularyId,SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
(
	SELECT FormularyId,TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT,
	ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC FROM
	(
			SELECT CC.ItemCode,CC.ItemName,FormularyId,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
			ISNULL(SUM(PD.Quantity*PRC.ItemRate),0) AS COGS,
			ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
			INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
			INNER JOIN SCPTnGoodReceiptNote_D PRC_RD ON PRC_RD.ItemCode = RD.ItemCode AND PRC_RD.BatchNo=RD.BatchNo
 				AND PRC_RD.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 				WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
			INNER JOIN SCPTnGoodReceiptNote_M PRM_RD ON PRC_RD.PARENT_TRNSCTN_ID = PRM_RD.TRNSCTN_ID 
			AND PRM_RD.GRNType=2 AND PRM_RD.IsActive=1 AND PRM_RD.IsApproved=1
				WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
				BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS REFUND,
			ISNULL((SELECT SUM(ROUND(RD.ReturnQty*PRIC.ItemRate,0)) FROM SCPTnSaleRefund_D RD
			INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
			INNER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 				AND PRIC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 				WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
			INNER JOIN SCPTnGoodReceiptNote_M PRICM ON PRIC.PARENT_TRNSCTN_ID = PRICM.TRNSCTN_ID 
			AND PRICM.GRNType=2 AND PRICM.IsActive=1 AND PRICM.IsApproved=1
				WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
				BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
			INNER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode	AND CAST(PD.CreatedDate AS DATE) 
			BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
			INNER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
			INNER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 				AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 				WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
			INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRC.PARENT_TRNSCTN_ID = PRCM.TRNSCTN_ID AND PRCM.GRNType=2 
			AND PRCM.IsActive=1 AND PRCM.IsApproved=1	GROUP BY CC.ItemCode,CC.ItemName,FormularyId
	)TMP
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.ItemCode = TMP.ItemCode AND CAST(PRD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
	LEFT OUTER JOIN SCPTnGoodReceiptNote_M PRM ON PRD.PARENT_TRNSCTN_ID = PRM.TRNSCTN_ID 
		AND PRM.IsActive=1 AND PRM.IsApproved=1 AND PRM.GRNType=2

	GROUP BY FormularyId,TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
)TMPP 
GROUP BY FormularyId
)TMPPP  
GROUP BY CASE WHEN FormularyId=0 THEN 'Nom-Formulary' ELSE 'Formulary' END

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPLpPurchasePercentage]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetLpPurchasePercentage]

AS BEGIN

	DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
	DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
	DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
	DECLARE @FLAG AS BIT = 0;								  --For loop


	WHILE @FLAG = 0
	BEGIN
		SET @FLAG = 1;
		IF @REPORT_DAY = 1     -- Sunday Condition
		BEGIN 
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END 
		IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
		BEGIN
			SET @FLAG = 0;
			SET @DAYS_DIFF = @DAYS_DIFF +1;
			SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
			SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
		END
	END

	SELECT ISNULL(SUM(NonFormlary),0) NonFormlary,ISNULL(SUM(Formlary),0) Formlary 
	FROM (
		SELECT CASE WHEN CC.FormularyId=0 THEN SUM(PRC.NetAmount) END AS NonFormlary,
		CASE WHEN CC.FormularyId!=0 THEN SUM(PRC.NetAmount) END AS Formlary FROM SCPTnGoodReceiptNote_M PRC
		INNER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.PARENT_TRNSCTN_ID = PRC.TRNSCTN_ID
		INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
		WHERE PRC.GRNType=2 AND CAST(PRC.TRNSCTN_DATE as date) BETWEEN
		CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date) AND PRC.IsApproved = 1
		GROUP BY CC.FormularyId
	)TMP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPLpPurchasePercentage_dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPLpPurchasePercentage_dashboard]

AS BEGIN
declare @Formlary_data as decimal, @NonFormlary_data as decimal,@Item_Non_Formlary_Data as decimal,@Item_Formlary_data as decimal



	SELECT @NonFormlary_data =ISNULL(SUM(NonFormlary/30),0),
	@Formlary_data = ISNULL(SUM(Formlary/30),0)
	FROM (
		SELECT CASE WHEN CC.FormularyId=0 THEN SUM(PRC.NetAmount) END AS NonFormlary,
		CASE WHEN CC.FormularyId!=0 THEN SUM(PRC.NetAmount) END AS Formlary FROM SCPTnGoodReceiptNote_M PRC
		INNER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.PARENT_TRNSCTN_ID = PRC.TRNSCTN_ID
		INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
		WHERE PRC.GRNType=2 AND CAST(PRC.TRNSCTN_DATE as date) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		AND PRC.IsApproved = 1
		GROUP BY CC.FormularyId
	)TMP

		
	select @Item_Non_Formlary_Data = count(NonFormlary) ,
	@Item_Formlary_data = count(Formlary)   from(
	SELECT 
		CASE WHEN CC.FormularyId=0 THEN PRC.NetAmount END AS NonFormlary,	
		CASE WHEN CC.FormularyId!=0 THEN PRC.NetAmount END AS Formlary	
		FROM SCPTnGoodReceiptNote_M PRC
		INNER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.PARENT_TRNSCTN_ID = PRC.TRNSCTN_ID
		INNER JOIN SCPStItem_M CC ON CC.ItemCode = PRD.ItemCode
		WHERE 
		PRC.GRNType=2 
		AND CAST(PRC.TRNSCTN_DATE as date) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		 AND PRC.IsApproved = 1
		 )ttr

select convert(varchar,@Formlary_data) as  Formlary_data, convert(varchar,@NonFormlary_data) as NonFormlary_data , 
convert(varchar,@Item_Non_Formlary_Data) as Item_Non_Formlary_Data , convert(varchar,@Item_Formlary_data) as Item_Formlary_data 

end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPLPSaleProfit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPLPSaleProfit]

AS BEGIN

SELECT CAST(ROUND(CAST((SALE-COGS) AS FLOAT)*100/CAST(SALE AS FLOAT),1) AS VARCHAR(50)) +' %' as LPprofit FROM
(
SELECT SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
(	
	SELECT TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT,
	ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC FROM
	(
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
		ISNULL(SUM(PD.Quantity*PRC.ItemRate),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		INNER JOIN SCPTnGoodReceiptNote_D PRC_RD ON PRC_RD.ItemCode = RD.ItemCode AND PRC_RD.BatchNo=RD.BatchNo
 			AND PRC_RD.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		INNER JOIN SCPTnGoodReceiptNote_M PRM_RD ON PRC_RD.PARENT_TRNSCTN_ID = PRM_RD.TRNSCTN_ID AND PRM_RD.GRNType=2 AND PRM_RD.IsActive=1 AND PRM_RD.IsApproved=1
			WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
			BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
			AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS REFUND,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*PRIC.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		INNER JOIN SCPTnGoodReceiptNote_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = RD.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		INNER JOIN SCPTnGoodReceiptNote_M PRICM ON PRIC.PARENT_TRNSCTN_ID = PRICM.TRNSCTN_ID AND PRICM.GRNType=2 AND PRICM.IsActive=1 AND PRICM.IsApproved=1
			WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
			BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
			AND EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		INNER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode	AND CAST(PD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND EOMONTH(dateadd(m, -1,GETDATE()))
		INNER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
		INNER JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = CC.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRC.PARENT_TRNSCTN_ID = PRCM.TRNSCTN_ID AND PRCM.GRNType=2 AND PRCM.IsActive=1 AND PRCM.IsApproved=1
		GROUP BY CC.ItemCode,CC.ItemName
	)TMP
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D PRD ON PRD.ItemCode = TMP.ItemCode AND CAST(PRD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND EOMONTH(dateadd(m, -1,GETDATE()))
	LEFT OUTER JOIN SCPTnGoodReceiptNote_M PRM ON PRD.PARENT_TRNSCTN_ID = PRM.TRNSCTN_ID 
		AND PRM.IsActive=1 AND PRM.IsApproved=1 AND PRM.GRNType=2

	GROUP BY TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
)TMPP
)TMPPP

END


	  



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMANUAL_DEMANDS_DASHBOARD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,MOIZ_HUSSAIN>
-- Create date: <Create Date, 9/16/2019 10:12:22 AM,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[Sp_SCPGet30DaysDemandsSummary] 

AS
BEGIN
	declare @MANUAL_DEMAND as int, @AUTO_DEMANDS as int ,
	 @ITEM_MANUAL as int, @AMOUNT_MANUAL AS INT, @ITEM_AUTO AS INT, @AMOUNT_AUTO AS INT,
	 @AUTO_PERCENTAGE AS DECIMAL, @MANUAL_PERCENATAGE AS decimal ,
	 @AUTO_PLUS_MANUAL_SUM AS INT 
	
	
	SELECT @MANUAL_DEMAND= SUM(MANUAL_DMND)  ,@AMOUNT_MANUAL = SUM(MANUAL_AMT) ,
@AUTO_DEMANDS = SUM(AUTO_DMND)  ,@AMOUNT_AUTO = SUM(AUTO_AMT)  FROM
(
SELECT CASE WHEN DemandType='A' THEN COUNT(DISTINCT MM.TRNSCTN_ID) END AS AUTO_DMND,
CASE WHEN DemandType='M' THEN COUNT(DISTINCT MM.TRNSCTN_ID) END AS MANUAL_DMND,
CASE WHEN DemandType='A' THEN SUM(DD.DemandQty*CostPrice) END AS AUTO_AMT,
CASE WHEN DemandType='M' THEN SUM(DD.DemandQty*CostPrice) END AS MANUAL_AMT FROM SCPTnDemand_M MM
INNER JOIN SCPTnDemand_D DD ON MM.TRNSCTN_ID = DD.PARENT_TRNSCTN_ID
LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = DD.ItemCode AND PRIC.FromDate <= TRNSCTN_DATE and PRIC.ToDate >= TRNSCTN_DATE
WHERE CAST(TRNSCTN_DATE AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) AND MM.IsActive=1
GROUP BY CAST(TRNSCTN_DATE AS DATE),DemandType
)TMP 
SELECT @AUTO_PERCENTAGE = (@AUTO_DEMANDS + @MANUAL_DEMAND )

SELECT FORMAT (@AUTO_DEMANDS/@AUTO_PERCENTAGE,'###%') AS AUTO_PERCENTAGE, @AUTO_DEMANDS AS ITEM_AUTO, 
		FORMAT(@AMOUNT_AUTO/@AUTO_DEMANDS,'###,###') AS AUTO_AMOUNT,
		FORMAT (@MANUAL_DEMAND/@AUTO_PERCENTAGE,'###%') AS MANUAL_PERCENTAGE,@MANUAL_DEMAND AS ITEM_MANUAL,
			FORMAT(@AMOUNT_MANUAL/@MANUAL_DEMAND,'###,###') AS MANUAL_AMOUNT

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPManualDemand]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetLastDayDemandSummary] 
AS
BEGIN
		  DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
		  --SELECT @REPORT_DATE
  
   				select DemandType, count(*) value from SCPTnDemand_M
				where IsActive =1 
				and
				CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
				group by DemandType,CAST(CreatedDate AS date)
				order by DemandType,CAST(CreatedDate AS date)
		
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPManualPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPLastDayPRSummary] 
AS
BEGIN
	 
	      DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END

		  select PRCRMNT_TYPE, count(*)  value  from SCPTnPurchaseRequisition_M
		  where IsActive = 1 and
		  CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE as date) AND CAST(@REPORT_DATE as date)
		  group by PRCRMNT_TYPE
		  ORDER BY PRCRMNT_TYPE ASC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPManufacturerPurchaseDetails]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[Sp_SCPRptManufacturerPurchaseDetails]
@FromDate varchar(50),
@ToDate varchar(50),
@Mnfctur_Id int
AS
BEGIN

	SET NOCOUNT ON;



	SELECT SCPStItem_M.ItemCode AS ItemCode,SCPStItem_M.ItemName AS NAME,MAN.ManufacturerName AS ManufacturerName ,SUM(GRN.RecievedQty) AS QTY,MAX(GRN.ItemRate) AS PRIC,
	SUM(GRN.NetAmount) AS AMOUNT FROM SCPTnGoodReceiptNote_D GRN
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=GRN.ItemCode AND SCPStItem_M.ManufacturerId=@Mnfctur_Id
	INNER JOIN SCPTnGoodReceiptNote_M GRNM ON GRN.PARENT_TRNSCTN_ID = GRNM.TRNSCTN_ID
	INNER JOIN SCPStManufactutrer MAN ON SCPStItem_M.ManufacturerId = MAN.ManufacturerId
	WHERE  cast(GRNM.TRNSCTN_DATE as date) 
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	GROUP BY SCPStItem_M.ItemCode,SCPStItem_M.ItemName,MAN.ManufacturerName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPManufacturersPurchaseSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[Sp_SCPRptManufacturersPurchaseSummary]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT MAN.ManufacturerName AS MANUFACTURER_NM, SUM(GRN.NetAmount) AS AMOUNT FROM SCPStManufactutrer MAN 
	INNER JOIN SCPStItem_M ITM ON ITM.ManufacturerId = MAN.ManufacturerId
	INNER JOIN SCPTnGoodReceiptNote_D GRN ON GRN.ItemCode = ITM.ItemCode
	INNER JOIN SCPTnGoodReceiptNote_M GRNM ON GRN.PARENT_TRNSCTN_ID = GRNM.TRNSCTN_ID
	WHERE cast(GRNM.TRNSCTN_DATE as date) 
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	GROUP BY MAN.ManufacturerName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonhtlySale]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetCurrentYearMonhtlySale]
AS
BEGIN
	SELECT SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max)) as Year_Month,
       right(convert(varchar, CreatedDate, 103), 7) as CreatedDate,
       SUM(ROUND(Quantity*ItemRate,0)) AS TotalSales FROM SCPTnSale_D
	   --WHERE CreatedDate BETWEEN DATEADD(YEAR,-1,GETDATE()) AND GETDATE() 
	   WHERE Year(CreatedDate) = Year(GETDATE()) AND IsActive=1
  GROUP BY right(convert(varchar, CreatedDate, 103), 7),SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max))
  ORDER BY right(convert(varchar, CreatedDate, 103), 7)

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyGnrlPurchase]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetMonthlyGeneralPurchase]
AS
BEGIN

SELECT Year_Month,CreatedDate,TotalPurchase,GnrlPurchase,(GnrlPurchase*100)/TotalPurchase AS GnrlPrchsPrcntg FROM
 (
 SELECT SubString(Convert(Varchar(Max), SCPTnGoodReceiptNote_M.CreatedDate,0), 1, 3) + '-' + Cast(Year(SCPTnGoodReceiptNote_M.CreatedDate) As Varchar(Max)) as Year_Month, 
 right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7) as CreatedDate,SUM(SCPTnGoodReceiptNote_M.NetAmount) AS TotalPurchase,isnull((SELECT SUM(NetAmount) FROM SCPTnGoodReceiptNote_M PRC 
 INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId=PRC.SupplierId WHERE PRC.WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouse WHERE ItemTypeId=1 AND
 IsActive=1) AND SCPStSupplier.SupplierCategoryId=1 AND SCPStSupplier.IsActive=1 AND right(convert(varchar, PRC.CreatedDate, 103), 7)=right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7)),0) 
 AS GnrlPurchase FROM SCPTnGoodReceiptNote_M WHERE SCPTnGoodReceiptNote_M.WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouse  WHERE ItemTypeId=1 AND IsActive=1)
 AND SCPTnGoodReceiptNote_M.IsActive=1 GROUP BY right(convert(varchar, SCPTnGoodReceiptNote_M.CreatedDate, 103), 7), SubString(Convert(Varchar(Max), SCPTnGoodReceiptNote_M.CreatedDate,0), 1, 3)
 + '-' + Cast(Year(SCPTnGoodReceiptNote_M.CreatedDate) As Varchar(Max))
 )tmp ORDER BY right(convert(varchar, CreatedDate, 103), 7)

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyInventoryDetailDayWisePOS]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailPOS_D]

@WraehouseName INT,
@ThisDay VARCHAR(50)
as
begin
SELECT CONVERT(date,@ThisDay,103) AS 
       Date, 
       OpeningClose, 
       sale, 
       sale_refund, 
       issued_amt, 
       return_pos_amt, 
       discard, 
       adj, 
       OpeningClose - sale + sale_refund + issued_amt - return_pos_amt - discard 
       - adj 
            Closing 
FROM   (SELECT Sum(OpeningClose * (CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END))      AS OpeningClose, 
               Sum(sale * (CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END))           AS SALE, 
               Sum(sale_refund * (CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END))    AS SALE_REFUND, 
               Sum(adj)  AS ADJ, 
               Sum(issued_qty * (CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END))     AS ISSUED_AMT, 
               Sum(return_pos_qty * (CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS RETURN_POS_AMT, 
               Sum(discard)                   AS DISCARD 
        FROM   (SELECT SCPStItem_M.ItemCode, 
                       SCPTnStock_M.BatchNo, 
                       Isnull((SELECT TOP 1 INV.ItemBalance 
                               FROM   SCPTnStock_D INV 
                               WHERE  INV.ItemCode = SCPStItem_M.ItemCode 
                                      AND INV.WraehouseId = SCPTnStock_M.WraehouseId 
                                      AND INV.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(INV.CreatedDate AS DATE) < Cast( 
                                          CONVERT(DATE, @ThisDay, 103) AS 
                                          DATE) 
                               ORDER  BY INV.CreatedDate DESC), 0) AS OpeningClose, 
                       Isnull((SELECT Sum(ItemPackingQuantity) 
                               FROM   SCPTnPharmacyIssuance_D PHM 
                                      INNER JOIN SCPTnStock_D 
                                              ON SCPTnStock_D.TransactionDocumentId = 
                                                 PHM.parent_trnsctn_id 
                                                 AND SCPTnStock_D.ItemCode = PHM.ItemCode 
                               WHERE  PHM.ItemCode = SCPStItem_M.ItemCode 
                                      AND SCPTnStock_D.BatchNo = SCPTnStock_M.BatchNo 
                                      AND SCPTnStock_D.WraehouseId = SCPTnStock_M.WraehouseId 
                                      AND Cast(PHM.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE ) 
                                      AND PHM.IsActive = 1), 0) AS ISSUED_QTY, 
                       Isnull((SELECT Sum(PHM.ReturnQty) 
                               FROM   SCPTnReturnToStore_D PHM 
                                      INNER JOIN SCPTnReturnToStore_M MM 
                                              ON MM.trnsctn_id = 
                                                 PHM.parent_trnsctn_id 
                                                 AND MM.FromWarehouseId = 
                                                     SCPTnStock_M.WraehouseId 
                               WHERE  PHM.ItemCode = SCPStItem_M.ItemCode 
                                      AND PHM.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PHM.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE ) 
                                      AND PHM.IsActive = 1), 0) AS RETURN_POS_QTY 
                       , 
                       Isnull((SELECT Sum(PHD.ReturnQty) 
                               FROM   SCPTnSaleRefund_D PHD 
                               WHERE  PHD.ItemCode = SCPStItem_M.ItemCode 
                                      AND PHD.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PHD.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE ) 
                                      AND PHD.IsActive = 1), 0) AS SALE_REFUND, 
                       Isnull((SELECT Sum(PHD.Quantity) 
                               FROM   SCPTnSale_D PHD 
                               WHERE  PHD.ItemCode = SCPStItem_M.ItemCode 
                                      AND PHD.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PHD.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE ) 
                                      AND PHD.IsActive = 1), 0) AS SALE, 
                       Isnull((SELECT Sum(SCPTnItemDiscard_D.Amount) 
                               FROM   SCPTnItemDiscard_D 
                                      INNER JOIN SCPTnItemDiscard_M 
                                              ON SCPTnItemDiscard_D.parent_trans_id = 
                                                 SCPTnItemDiscard_M.transc_id 
                               WHERE  ItemCode = SCPStItem_M.ItemCode 
                                      AND WraehouseId = SCPTnStock_M.WraehouseId 
                                      AND IsApprove = 1 
                                      AND Cast(SCPTnItemDiscard_M.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE ) 
									  ), 0)               AS DISCARD, 
                       Isnull((SELECT Sum( 
                              ( IND.CurrentStock - ItemBalance )* IND.ItemRate) 
                               FROM   SCPTnAdjustment_D IND 
                                      INNER JOIN SCPTnAdjustment_M INM 
                                              ON INM.trnsctn_id = 
                                                 IND.parent_trnsctn_id 
                                                 AND WraehouseId = SCPTnStock_M.WraehouseId 
                               WHERE  IND.ItemCode = SCPStItem_M.ItemCode 
                                      AND IND.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(IND.CreatedDate AS DATE) = Cast ( CONVERT(DATE, @ThisDay, 103) AS DATE )  
                                      AND INM.IsApprove = 1 
                                      AND INM.IsActive = 1), 0) AS ADJ, 
                       SCPStRate.CostPrice AS CostPrice 
                FROM   SCPStItem_M 
                       INNER JOIN SCPTnStock_M 
                               ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId = @WraehouseName 
                       LEFT OUTER JOIN SCPStRate 
                               ON SCPStRate.ItemCode = SCPStItem_M.ItemCode 
                                  AND ItemRateId = (SELECT Max(ItemRateId) 
                                                     FROM   SCPStRate CPP 
                                                     WHERE 
                                      SCPTnStock_M.CreatedDate BETWEEN 
                                      CPP.FromDate AND CPP.ToDate 
                                      AND 
                                                    CPP.ItemCode = SCPStItem_M.ItemCode) 
               -- WHERE  SCPStItem_M.IsActive = 1  
                --GROUP  BY SCPStItem_M.ItemCode, 
                --          SCPTnStock_M.BatchNo, 
                --          SCPStRate.CostPrice, 
                --          SCPTnPharmacyIssuance_D.ItemRate
						  )TMP
						  LEFT OUTER JOIN SCPTnGoodReceiptNote_D 
                                    ON SCPTnGoodReceiptNote_D.ItemCode = TMP.ItemCode 
                                       AND SCPTnGoodReceiptNote_D.BatchNo = TMP.BatchNo 
                                       AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = 
                                           (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId 
                                            FROM   SCPTnGoodReceiptNote_D 
                                            WHERE  SCPTnGoodReceiptNote_D.ItemCode = 
                                                   TMP.ItemCode 
                                                   AND SCPTnGoodReceiptNote_D.BatchNo = 
                                                       TMP.BatchNo ORDER BY CreatedDate DESC) 
                      
						  )TMPP 

						  end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyInventoryStatement]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryStatementMSS] 
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin

 declare @WraehouseId Int=@WraehouseName,
 @First varchar(50)=@FirstDate,
 @Limit varchar(50)=@LimitDate

      SELECT Format(CAST(CONVERT(date,@First,103) as date),'MMM-yyyy') as Year_Month,
 OpeningClose,PURCHASE,LOCAL_PURCHASE,ISSUED_AMT,RETURN_POS_AMT,RTN_SUPLR,DISCARD,BonusQty_AMT,ADJ,
 OpeningClose+PURCHASE+LOCAL_PURCHASE-ISSUED_AMT+RETURN_POS_AMT-RTN_SUPLR-DISCARD+BonusQty_AMT-ADJ Closing FROM  
	 (    
        SELECT SUM(OpeningClose*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS OpeningClose,
		SUM(PURCHASE) AS PURCHASE,SUM(LOCAL_PURCHASE) AS LOCAL_PURCHASE,SUM(BonusQty_AMT) AS BonusQty_AMT,SUM(ADJ) AS ADJ,
		SUM(ISSUED_QTY*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS ISSUED_AMT,
		SUM(RETURN_POS_QTY*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS RETURN_POS_AMT,
		SUM(RTN_SUPLR) AS RTN_SUPLR,SUM(DISCARD) AS DISCARD FROM
            (
			SELECT SCPStItem_M.ItemCode,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,OpeningClose,ISSUED_QTY,RETURN_POS_QTY,
			PURCHASE,LOCAL_PURCHASE,BonusQty_AMT,RTN_SUPLR,DISCARD,ADJ FROM SCPStItem_M 
			INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId=@WraehouseId
			LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = SCPStItem_M.ItemCode)

			OUTER APPLY (SELECT TOP 1 ISNULL(INV.ItemBalance,0) AS OpeningClose FROM SCPTnStock_D INV WHERE INV.ItemCode= SCPStItem_M.ItemCode 
							AND INV.WraehouseId=SCPTnStock_M.WraehouseId AND INV.BatchNo=SCPTnStock_M.BatchNo
							AND CAST(INV.CreatedDate as date) < CAST(CONVERT(date,@First,103) as date) ORDER BY INV.CreatedDate DESC) AS OpeningClose 
			OUTER APPLY (SELECT ISNULL(SUM(ItemPackingQuantity),0)  AS ISSUED_QTY FROM SCPTnPharmacyIssuance_D PHM 
							INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = PHM.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=PHM.ItemCode
							WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_D.BatchNo = SCPTnStock_M.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
 							AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 							AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1) AS ISSUED_QTY
			OUTER APPLY (SELECT ISNULL(SUM(PHM.ReturnQty),0) AS RETURN_POS_QTY FROM SCPTnReturnToStore_D PHM 
							INNER JOIN SCPTnReturnToStore_M MM ON MM.TRNSCTN_ID = PHM.PARENT_TRNSCTN_ID AND MM.ToWarehouseId = SCPTnStock_M.WraehouseId
							INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = PHM.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=PHM.ItemCode
							AND SCPTnStock_D.BatchNo = PHM.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
							WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND PHM.BatchNo = SCPTnStock_M.BatchNo 
 							AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 							AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1 AND MM.IsApprove=1) AS RETURN_POS_QTY
			OUTER APPLY (SELECT ISNULL(SUM(PRC.NetAmount),0) AS PURCHASE FROM SCPTnGoodReceiptNote_D PRC
 							INNER JOIN SCPTnGoodReceiptNote_M GRN ON GRN.TRNSCTN_ID = PRC.PARENT_TRNSCTN_ID AND WraehouseId=SCPTnStock_M.WraehouseId
 							WHERE GRN.GRNType=1 AND PRC.ItemCode = SCPStItem_M.ItemCode AND PRC.BatchNo = SCPTnStock_M.BatchNo
 							AND CAST(PRC.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 							AND CAST(CONVERT(date,@Limit,103) as date) AND GRN.IsApproved=1 AND GRN.IsActive=1) AS PURCHASE
			OUTER APPLY (SELECT ISNULL(SUM(PRC.NetAmount),0) LOCAL_PURCHASE FROM SCPTnGoodReceiptNote_D PRC
 							INNER JOIN SCPTnGoodReceiptNote_M GRN ON GRN.TRNSCTN_ID = PRC.PARENT_TRNSCTN_ID AND WraehouseId=@WraehouseId
 							WHERE GRN.GRNType=2 AND PRC.ItemCode = SCPStItem_M.ItemCode AND PRC.BatchNo = SCPTnStock_M.BatchNo
 							AND CAST(PRC.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 							AND CAST(CONVERT(date,@Limit,103) as date) AND GRN.IsApproved=1 AND GRN.IsActive=1) AS LOCAL_PURCHASE
			OUTER APPLY (SELECT ISNULL(SUM(BonusQty*ItemRate),0) BonusQty_AMT FROM SCPTnGoodReceiptNote_D
	   						INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId WHERE WraehouseId=@WraehouseId AND 
							SCPTnGoodReceiptNote_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo AND SCPTnGoodReceiptNote_D.IsActive=1 
							AND SCPTnGoodReceiptNote_M.IsActive=1 AND SCPTnGoodReceiptNote_M.IsApproved=1 AND CAST(SCPTnGoodReceiptNote_M.CreatedDate AS DATE) 
							BETWEEN CAST(CONVERT(date,@First,103) as date) AND CAST(CONVERT(date,@Limit,103) as date)) AS BonusQty_AMT
			OUTER APPLY (SELECT ISNULL(SUM(SCPTnReturnToSupplier_D.NetAmount),0) RTN_SUPLR FROM SCPTnReturnToSupplier_D
							INNER JOIN SCPTnReturnToSupplier_M ON SCPTnReturnToSupplier_D.PARENT_TRNSCTN_ID = SCPTnReturnToSupplier_M.TRNSCTN_ID 
							INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = SCPTnReturnToSupplier_D.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=SCPTnReturnToSupplier_D.ItemCode
							AND SCPTnStock_D.BatchNo = SCPTnReturnToSupplier_D.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
							WHERE SCPTnReturnToSupplier_M.WraehouseId=@WraehouseId AND SCPTnReturnToSupplier_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnReturnToSupplier_D.BatchNo = SCPTnStock_M.BatchNo 
							AND SCPTnReturnToSupplier_M.IsApproved=1 AND SCPTnReturnToSupplier_M.IsActive=1 AND CAST(SCPTnReturnToSupplier_M.CreatedDate AS DATE) 
							BETWEEN CAST(CONVERT(date,@First,103) as date) AND CAST(CONVERT(date,@Limit,103) as date)) AS RTN_SUPLR
			OUTER APPLY (SELECT ISNULL(SUM(SCPTnItemDiscard_D.Amount),0) DISCARD FROM SCPTnItemDiscard_D 
							INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID 
							INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = SCPTnItemDiscard_D.PARENT_TRANS_ID AND SCPTnStock_D.ItemCode=SCPTnItemDiscard_D.ItemCode
							AND SCPTnStock_D.BatchNo = SCPTnItemDiscard_D.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
							WHERE SCPTnItemDiscard_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnItemDiscard_M.WraehouseId=@WraehouseId AND IsApprove=1 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
							BETWEEN CAST(CONVERT(date,@First,103) as date) AND CAST(CONVERT(date,@Limit,103) as date)) AS DISCARD
			OUTER APPLY (SELECT ISNULL(SUM((IND.CurrentStock-ItemBalance)*ItemRate),0) ADJ FROM SCPTnAdjustment_D IND
							INNER JOIN SCPTnAdjustment_M INM ON INM.TRNSCTN_ID = IND.PARENT_TRNSCTN_ID AND WraehouseId=@WraehouseId
							INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = IND.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=IND.ItemCode
							AND SCPTnStock_D.BatchNo = IND.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
							WHERE IND.ItemCode = SCPStItem_M.ItemCode AND IND.BatchNo = SCPTnStock_M.BatchNo 
							AND CAST(IND.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date) 
							AND CAST(CONVERT(date,@Limit,103) as date) AND INM.IsApprove=1 AND INM.IsActive=1) AS ADJ
			WHERE SCPTnStock_M.WraehouseId=@WraehouseId --SCPStItem_M.IsActive=1 AND 
        )TMP LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = TMP.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=TMP.BatchNo
 			AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 			WHERE SCPTnGoodReceiptNote_D.ItemCode = TMP.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = TMP.BatchNo ORDER BY CreatedDate DESC)
   )TMPP
 end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyInventoryStatementDaywise]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailMSS_D] 
@WraehouseName Int,
@ThisDay varchar(50)
as
begin
SELECT 
--Substring(CONVERT(VARCHAR(max), Cast(CONVERT(DATE, @ThisDay, 103) AS 
--       DATE), 0) 
--       , 1, 3) 
--       + '-' 
--       + Cast(Year(Cast(CONVERT
	   convert(DATE, @ThisDay, 103)  
	   --AS VARCHAR(max 
    --   )) AS 
       Year_Month, 
       OpeningClose, 
       purchase, 
       local_purchase, 
       issued_amt, 
       return_pos_amt, 
       rtn_suplr, 
       discard, 
       BonusQty_amt, 
       adj, 
       OpeningClose + purchase + local_purchase - issued_amt + return_pos_amt 
       - rtn_suplr 
       - discard + BonusQty_amt - adj 
       Closing 
FROM   (SELECT Sum(OpeningClose * CostPrice)      AS OpeningClose, 
               Sum(purchase)                  AS PURCHASE, 
               Sum(local_purchase)            AS LOCAL_PURCHASE, 
               Sum(BonusQty_amt)                 AS BonusQty_AMT, 
               Sum(adj)                       AS ADJ, 
               Sum(issued_qty * CostPrice)     AS ISSUED_AMT, 
               Sum(return_pos_qty * CostPrice) AS RETURN_POS_AMT, 
               Sum(rtn_suplr)                 AS RTN_SUPLR, 
               Sum(discard)                   AS DISCARD 
        FROM   (SELECT SCPStItem_M.ItemCode, 
                       SCPTnStock_M.BatchNo, 
                       Isnull((SELECT TOP 1 INV.ItemBalance 
                               FROM   SCPTnStock_D INV 
                               WHERE  INV.ItemCode = SCPStItem_M.ItemCode 
                                      AND INV.WraehouseId = @WraehouseName 
                                      AND INV.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(INV.CreatedDate AS DATE) < Cast( 
                                          CONVERT(DATE, @ThisDay, 103) AS 
                                          DATE) 
                               ORDER  BY INV.CreatedDate DESC), 0) 
                       AS 
                               OpeningClose, 
                       Isnull((SELECT Sum(ItemPackingQuantity) 
                               FROM   SCPTnPharmacyIssuance_D PHM 
                                      INNER JOIN SCPTnStock_D 
                                              ON SCPTnStock_D.TransactionDocumentId = 
                                                 PHM.parent_trnsctn_id 
                                                 AND SCPTnStock_D.ItemCode = PHM.ItemCode 
                               WHERE  PHM.ItemCode = SCPStItem_M.ItemCode 
                                      AND SCPTnStock_D.BatchNo = SCPTnStock_M.BatchNo 
                                      AND SCPTnStock_D.WraehouseId = @WraehouseName 
                                      AND Cast(PHM.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) 
                                      AND PHM.IsActive = 1), 0) 
                       AS 
                               ISSUED_QTY, 
                       Isnull((SELECT Sum(PHM.ReturnQty) 
                               FROM   SCPTnReturnToStore_D PHM 
                                      INNER JOIN SCPTnReturnToStore_M MM 
                                              ON MM.trnsctn_id = 
                                                 PHM.parent_trnsctn_id 
                                                 AND MM.ToWarehouseId = 
                                                     @WraehouseName 
                               WHERE  PHM.ItemCode = SCPStItem_M.ItemCode 
                                      AND PHM.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PHM.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) 
                                      AND PHM.IsActive = 1  AND MM.IsApprove=1), 0) 
                       AS 
                               RETURN_POS_QTY, 
                       Isnull((SELECT Sum(PRC.NetAmount) 
                               FROM   SCPTnGoodReceiptNote_D PRC 
                                      INNER JOIN SCPTnGoodReceiptNote_M GRN 
                                              ON GRN.trnsctn_id = 
                                                 PRC.parent_trnsctn_id 
                                                 AND WraehouseId = @WraehouseName 
                               WHERE  GRN.GRNType = 1 
                                      AND PRC.ItemCode = SCPStItem_M.ItemCode 
                                      AND PRC.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PRC.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) 
                                      AND GRN.IsApproved = 1 
                                      AND GRN.IsActive = 1), 0) 
                       AS 
                               PURCHASE, 
                       Isnull((SELECT Sum(PRC.NetAmount) 
                               FROM   SCPTnGoodReceiptNote_D PRC 
                                      INNER JOIN SCPTnGoodReceiptNote_M GRN 
                                              ON GRN.trnsctn_id = 
                                                 PRC.parent_trnsctn_id 
                                                 AND WraehouseId = @WraehouseName 
                               WHERE  GRN.GRNType = 2 
                                      AND PRC.ItemCode = SCPStItem_M.ItemCode 
                                      AND PRC.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(PRC.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) 
                                      AND GRN.IsApproved = 1 
                                      AND GRN.IsActive = 1), 0) 
                       AS 
                               LOCAL_PURCHASE, 
                       Isnull((SELECT Sum(BonusQty * ItemRate) 
                               FROM   SCPTnGoodReceiptNote_D 
                                      INNER JOIN SCPTnGoodReceiptNote_M 
                                              ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = 
                                                 SCPTnGoodReceiptNote_M.GoodReceiptNoteId 
                               WHERE  WraehouseId = @WraehouseName 
                                      AND SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode  AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo
                                      AND SCPTnGoodReceiptNote_D.IsActive = 1 
                                      AND SCPTnGoodReceiptNote_M.IsActive = 1 
									   AND SCPTnGoodReceiptNote_M.IsApproved=1
                                      AND Cast(SCPTnGoodReceiptNote_M.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) ), 0) 
                       AS 
                               BonusQty_AMT, 
                       Isnull((SELECT Sum(SCPTnReturnToSupplier_D.NetAmount) 
                               FROM   SCPTnReturnToSupplier_D 
                                      INNER JOIN SCPTnReturnToSupplier_M 
                                              ON SCPTnReturnToSupplier_D.parent_trnsctn_id = 
                                                 SCPTnReturnToSupplier_M.trnsctn_id 
                               WHERE  WraehouseId = @WraehouseName 
                                      AND SCPTnReturnToSupplier_D.ItemCode = SCPStItem_M.ItemCode 
                                      AND SCPTnReturnToSupplier_D.BatchNo = SCPTnStock_M.BatchNo 
                                      AND SCPTnReturnToSupplier_M.IsApproved = 1 
                                      AND SCPTnReturnToSupplier_M.IsActive = 1 
                                      AND Cast(SCPTnReturnToSupplier_M.CreatedDate AS DATE) 
                                          = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          )), 
                       0) AS 
                               RTN_SUPLR, 
                       Isnull((SELECT Sum(SCPTnItemDiscard_D.Amount) 
                               FROM   SCPTnItemDiscard_D 
                                      INNER JOIN SCPTnItemDiscard_M 
                                              ON SCPTnItemDiscard_D.parent_trans_id = 
                                                 SCPTnItemDiscard_M.transc_id 
                               WHERE  ItemCode = SCPStItem_M.ItemCode 
                                      AND WraehouseId = @WraehouseName 
                                      AND IsApprove = 1 
                                      AND Cast(SCPTnItemDiscard_M.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          )), 0) 
                       AS 
                               DISCARD, 
                       Isnull((SELECT Sum( 
                              ( IND.CurrentStock - ItemBalance )*ItemRate) 
                               FROM   SCPTnAdjustment_D IND 
                                      INNER JOIN SCPTnAdjustment_M INM 
                                              ON INM.trnsctn_id = 
                                                 IND.parent_trnsctn_id 
                                                 AND WraehouseId = @WraehouseName 
                               WHERE  IND.ItemCode = SCPStItem_M.ItemCode 
                                      AND IND.BatchNo = SCPTnStock_M.BatchNo 
                                      AND Cast(IND.CreatedDate AS DATE) = Cast 
                                          ( 
                                          CONVERT(DATE, @ThisDay, 103) AS DATE 
                                          ) 
                                      AND INM.IsApprove = 1 
                                      AND INM.IsActive = 1), 0) 
                       AS 
                               ADJ, 
                       CASE 
                         WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice 
                         ELSE SCPTnGoodReceiptNote_D.ItemRate 
                       END 
                       AS 
                               CostPrice 
                FROM   SCPStItem_M 
                       INNER JOIN SCPTnStock_M 
                               ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode 
                                  AND SCPTnStock_M.WraehouseId = @WraehouseName 
                       LEFT OUTER JOIN SCPTnGoodReceiptNote_D 
                                    ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode 
                                       AND SCPTnGoodReceiptNote_D.BatchNo = SCPTnStock_M.BatchNo 
                                       AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = 
                                           (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId 
                                            FROM   SCPTnPharmacyIssuance_D 
                                            WHERE  SCPTnGoodReceiptNote_D.ItemCode = 
                                                   SCPStItem_M.ItemCode 
                                                   AND SCPTnGoodReceiptNote_D.BatchNo = 
                                                       SCPTnStock_M.BatchNo ORDER BY CreatedDate DESC) 
                       LEFT OUTER JOIN SCPStRate 
                               ON SCPStRate.ItemCode = SCPStItem_M.ItemCode 
                                  AND ItemRateId = (SELECT Max(ItemRateId) 
                                                     FROM   SCPStRate CPP 
                                                     WHERE 
                                      SCPTnStock_M.CreatedDate BETWEEN 
                                      CPP.FromDate AND CPP.ToDate 
                                      AND 
                                                    CPP.ItemCode = SCPStItem_M.ItemCode) 
               -- WHERE  SCPStItem_M.IsActive = 1 
                GROUP  BY SCPStItem_M.ItemCode, 
                          SCPTnStock_M.BatchNo, 
                          SCPStRate.CostPrice, 
                          SCPTnGoodReceiptNote_D.ItemRate)TMP)TMPP 
 
 
 
	   end
 

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyInventoryStatementDaywiseReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryDetailMSS_M]
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin
SET NOCOUNT ON
DECLARE @userData TABLE(
    
    [Date] datetime
);
DECLARE @FinalData TABLE(
    
    Year_Month varchar(50),
	OpeningClose decimal(18,2),
	purchase decimal(18,2),
	local_purchase decimal(18,2),
	issued_amt decimal(18,2),
	return_pos_amt decimal(18,2),
	rtn_suplr decimal(18,2),
	discard decimal(18,2),
	BonusQty_amt decimal(18,2),
	adj decimal(18,2),
	closing decimal(18,2)

);

insert into @userData([Date])
select CONVERT(date,inv1.CreatedDate ,103) as Date 
	from SCPTnStock_D inv1  
	where cast(inv1.CreatedDate as date) 
	between cast(CONVERT(date,@FirstDate  ,103) as date) and cast(CONVERT(date,@LimitDate  ,103) as date)
	group by CONVERT(date,inv1.CreatedDate ,103)

DECLARE @Date datetime;
DECLARE EMP_CURSOR CURSOR  
LOCAL  FORWARD_ONLY  FOR  
  select * from @userdata;
OPEN EMP_CURSOR  
FETCH NEXT FROM EMP_CURSOR INTO  @Date
WHILE @@FETCH_Status = 0  
BEGIN  

insert into @FinalData(Year_Month,OpeningClose,purchase,local_purchase,issued_amt,return_pos_amt,rtn_suplr,discard,BonusQty_amt,adj
,closing)
exec [dbo].[Sp_SCPMonthlyInventoryStatementDaywise] @WraehouseName,@Date
FETCH NEXT FROM EMP_CURSOR INTO  @Date 
END  
CLOSE EMP_CURSOR  
DEALLOCATE EMP_CURSOR  


select *,cast(Year_Month as datetime) as Data_Dt from @FinalData order by cast(Year_Month as datetime) 

end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyInventoryStatementPOS]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE procedure [dbo].[Sp_SCPRptMonthlyInventoryStatementPOS] 
@WraehouseName Int,
@FirstDate varchar(50),
@LimitDate varchar(50)
as
begin
 declare @WraehouseId Int=@WraehouseName,
 @First varchar(50)=@FirstDate,
 @Limit varchar(50)=@LimitDate

    SELECT Format(CAST(CONVERT(date,@First,103) as date),'MMM-yyyy') as Year_Month,
	 OpeningClose,SALE,SALE_REFUND,ISSUED_AMT,RETURN_POS_AMT,DISCARD,ADJ,
	 OpeningClose-SALE+SALE_REFUND+ISSUED_AMT-RETURN_POS_AMT-DISCARD-ADJ Closing FROM  
	 (    
        SELECT SUM(OpeningClose*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS OpeningClose,
		SUM(SALE*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS SALE,
		SUM(SALE_REFUND*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS SALE_REFUND,
		SUM(ADJ) AS ADJ,SUM(ISSUED_QTY*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS ISSUED_AMT,
		SUM(RETURN_POS_QTY*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS RETURN_POS_AMT,
		SUM(DISCARD) AS DISCARD FROM
            (
				SELECT SCPStItem_M.ItemCode,SCPTnStock_M.BatchNo,ISNULL((SELECT TOP 1 INV.ItemBalance FROM SCPTnStock_D INV
 				WHERE INV.ItemCode= SCPStItem_M.ItemCode AND INV.WraehouseId=SCPTnStock_M.WraehouseId AND INV.BatchNo=SCPTnStock_M.BatchNo
 				AND CAST(INV.CreatedDate as date) < CAST(CONVERT(date,@First,103) as date) ORDER BY INV.CreatedDate DESC),0) AS OpeningClose,
 				ISNULL((SELECT SUM(ItemPackingQuantity) FROM SCPTnPharmacyIssuance_D PHM 
				INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = PHM.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=PHM.ItemCode
				WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_D.BatchNo = SCPTnStock_M.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
 				AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 				AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1),0) AS ISSUED_QTY,
				ISNULL((SELECT SUM(PHM.ReturnQty) FROM SCPTnReturnToStore_D PHM 
				INNER JOIN SCPTnReturnToStore_M MM ON MM.TRNSCTN_ID = PHM.PARENT_TRNSCTN_ID AND MM.FromWarehouseId = SCPTnStock_M.WraehouseId
				WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND PHM.BatchNo = SCPTnStock_M.BatchNo 
 				AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 				AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1 AND MM.IsApprove=1),0) AS RETURN_POS_QTY,
 				ISNULL((SELECT SUM(PHD.ReturnQty) FROM SCPTnSaleRefund_D PHD
 				WHERE PHD.ItemCode = SCPStItem_M.ItemCode AND PHD.BatchNo = SCPTnStock_M.BatchNo
 				AND CAST(PHD.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 				AND CAST(CONVERT(date,@Limit,103) as date) AND PHD.IsActive=1),0) AS SALE_REFUND,
				ISNULL((SELECT SUM(PHD.Quantity)FROM SCPTnSale_D PHD
 				WHERE PHD.ItemCode = SCPStItem_M.ItemCode AND PHD.BatchNo = SCPTnStock_M.BatchNo
 				AND CAST(PHD.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 				AND CAST(CONVERT(date,@Limit,103) as date) AND PHD.IsActive=1),0) AS SALE,
				ISNULL((SELECT SUM(SCPTnItemDiscard_D.Amount) FROM SCPTnItemDiscard_D 
				INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID 
				WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=SCPTnStock_M.WraehouseId AND IsApprove=1 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
				BETWEEN CAST(CONVERT(date,@First,103) as date) AND CAST(CONVERT(date,@Limit,103) as date)),0) AS DISCARD,
				ISNULL((SELECT SUM((IND.CurrentStock-ItemBalance)*ItemRate) FROM SCPTnAdjustment_D IND
				INNER JOIN SCPTnAdjustment_M INM ON INM.TRNSCTN_ID = IND.PARENT_TRNSCTN_ID AND WraehouseId=SCPTnStock_M.WraehouseId
				WHERE IND.ItemCode = SCPStItem_M.ItemCode AND IND.BatchNo = SCPTnStock_M.BatchNo 
				AND CAST(IND.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date) 
				AND CAST(CONVERT(date,@Limit,103) as date) AND INM.IsApprove=1 AND INM.IsActive=1),0) AS ADJ, 
				SCPStRate.CostPrice FROM SCPStItem_M 
				INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId=@WraehouseId
 				LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode  
				AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
                WHERE  SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = SCPStItem_M.ItemCode) 
 				--WHERE SCPStItem_M.IsActive=1 
  	  		--GROUP BY SCPStItem_M.ItemCode,SCPTnStock_M.BatchNo,SCPStRate.CostPrice--,SCPTnPharmacyIssuance_D.ItemRate
  		    )TMP
                LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = TMP.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=TMP.BatchNo
 				AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D
 				WHERE SCPTnGoodReceiptNote_D.ItemCode = TMP.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = TMP.BatchNo ORDER BY CreatedDate DESC)
		)TMPP

		--SELECT Format(CAST(CONVERT(date,@First,103) as date),'MMM-yyyy') as Year_Month,
	 --OpeningClose,SALE,SALE_REFUND,ISSUED_AMT,RETURN_POS_AMT,DISCARD,ADJ,
	 --OpeningClose-SALE+SALE_REFUND+ISSUED_AMT-RETURN_POS_AMT-DISCARD-ADJ Closing FROM  
	 --(    
  --      SELECT SUM(OpeningClose*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS OpeningClose,
		--SUM(SALE*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS SALE,
		--SUM(SALE_REFUND*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS SALE_REFUND,
		--SUM(ADJ) AS ADJ,SUM(ISSUED_QTY*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS ISSUED_AMT,
		--SUM(RETURN_POS_QTY*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS RETURN_POS_AMT,
		--SUM(DISCARD) AS DISCARD FROM
  --          (
  --          SELECT SCPStItem_M.ItemCode,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,OpeningClose,ISSUED_QTY,
		--	RETURN_POS_QTY,SALE_REFUND,SALE,DISCARD,ADJ FROM SCPStItem_M 
		--	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_M.WraehouseId=@WraehouseId
		--	LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
		--	WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = SCPStItem_M.ItemCode)
		
		--	OUTER APPLY (SELECT TOP 1 ISNULL(INV.ItemBalance,0) OpeningClose FROM SCPTnStock_D INV
 	--						WHERE INV.ItemCode= SCPStItem_M.ItemCode AND INV.WraehouseId=SCPTnStock_M.WraehouseId AND INV.BatchNo=SCPTnStock_M.BatchNo
 	--						AND CAST(INV.CreatedDate as date) < CAST(CONVERT(date,@First,103) as date) ORDER BY INV.CreatedDate DESC) AS OpeningClose 
		--	OUTER APPLY (SELECT ISNULL(SUM(ItemPackingQuantity),0)  AS ISSUED_QTY FROM SCPTnPharmacyIssuance_D PHM 
		--					INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = PHM.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=PHM.ItemCode
		--					WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND SCPTnStock_D.BatchNo = SCPTnStock_M.BatchNo AND SCPTnStock_D.WraehouseId=SCPTnStock_M.WraehouseId
 	--						AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 	--						AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1) AS ISSUED_QTY
		--	OUTER APPLY (SELECT ISNULL(SUM(PHM.ReturnQty),0) RETURN_POS_QTY FROM SCPTnReturnToStore_D PHM 
		--					INNER JOIN SCPTnReturnToStore_M MM ON MM.TRNSCTN_ID = PHM.PARENT_TRNSCTN_ID AND MM.FromWarehouseId = SCPTnStock_M.WraehouseId
		--					WHERE PHM.ItemCode = SCPStItem_M.ItemCode AND PHM.BatchNo = SCPTnStock_M.BatchNo 
 	--						AND CAST(PHM.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 	--						AND CAST(CONVERT(date,@Limit,103) as date) AND PHM.IsActive=1) AS RETURN_POS_QTY
	 --      OUTER APPLY (SELECT ISNULL(SUM(PHD.ReturnQty),0) SALE_REFUND FROM SCPTnSaleRefund_D PHD
 	--						WHERE PHD.ItemCode = SCPStItem_M.ItemCode AND PHD.BatchNo = SCPTnStock_M.BatchNo
 	--						AND CAST(PHD.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 	--						AND CAST(CONVERT(date,@Limit,103) as date) AND PHD.IsActive=1) AS SALE_REFUND
		--   OUTER APPLY (SELECT ISNULL(SUM(PHD.Quantity),0) SALE FROM SCPTnSale_D PHD
 	--						WHERE PHD.ItemCode = SCPStItem_M.ItemCode AND PHD.BatchNo = SCPTnStock_M.BatchNo
 	--						AND CAST(PHD.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date)
 	--						AND CAST(CONVERT(date,@Limit,103) as date) AND PHD.IsActive=1) AS SALE
		--   OUTER APPLY (SELECT ISNULL(SUM(SCPTnItemDiscard_D.Amount),0) DISCARD FROM SCPTnItemDiscard_D 
		--					INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID WHERE ItemCode=SCPStItem_M.ItemCode 
		--					AND WraehouseId=SCPTnStock_M.WraehouseId AND IsApprove=1 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
		--					BETWEEN CAST(CONVERT(date,@First,103) as date) AND CAST(CONVERT(date,@Limit,103) as date)) AS DISCARD
		--   OUTER APPLY (SELECT ISNULL(SUM((IND.CurrentStock-ItemBalance)*ItemRate),0) ADJ FROM SCPTnAdjustment_D IND
		--					INNER JOIN SCPTnAdjustment_M INM ON INM.TRNSCTN_ID = IND.PARENT_TRNSCTN_ID AND WraehouseId=SCPTnStock_M.WraehouseId
		--					WHERE IND.ItemCode = SCPStItem_M.ItemCode AND IND.BatchNo = SCPTnStock_M.BatchNo 
		--					AND CAST(IND.CreatedDate AS date) BETWEEN CAST(CONVERT(date,@First,103) as date) 
		--					AND CAST(CONVERT(date,@Limit,103) as date) AND INM.IsApprove=1 AND INM.IsActive=1) AS ADJ
		--	WHERE SCPStItem_M.IsActive=1 
  --     )TMP
		--LEFT OUTER JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode = TMP.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo=TMP.BatchNo
 	--	AND SCPTnPharmacyIssuance_D.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 	--	WHERE SCPTnPharmacyIssuance_D.ItemCode = TMP.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = TMP.BatchNo ORDER BY CreatedDate DESC)
  --)TMPP
   end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPMonthlyPurchase]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptCurrentYearMonthlyPurchase]
AS
BEGIN
   SELECT SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max)) as Year_Month,
       right(convert(varchar, CreatedDate, 103), 7) as CreatedDate,
       SUM(NetAmount) AS TotalPurchase FROM SCPTnGoodReceiptNote_M
	   WHERE WraehouseId IN(SELECT WraehouseId FROM SCPStWraehouse WHERE ItemTypeId=2 AND IsActive=1) 
	  -- AND CreatedDate BETWEEN DATEADD(YEAR,-1,GETDATE()) AND GETDATE() 
	   AND Year(CreatedDate) = Year(GETDATE())AND IsActive=1
   GROUP BY right(convert(varchar, CreatedDate, 103), 7),SubString(Convert(Varchar(Max), CreatedDate,0), 1, 3) + '/' + Cast(Year(CreatedDate) As Varchar(Max))
   ORDER BY right(convert(varchar, CreatedDate, 103), 7)  
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPNoDiscountItemManufacturerDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptNoDiscountItemManufacturerDetail]
@FromDate as varchar(50),
@ToDate as varchar(50),
@MANUFCTR_ID as int
AS
BEGIN

 SELECT DISTINCT CASE WHEN SCPTnGoodReceiptNote_D.DiscountValue=0 THEN 'No Discount' ELSE 'Discounted items' END AS Discount_Status,
 SCPTnGoodReceiptNote_D.ItemCode,SCPStItem_M.ItemName,SCPTnGoodReceiptNote_D.ItemRate FROM SCPTnGoodReceiptNote_D
 INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
 INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId=SCPTnGoodReceiptNote_M.GoodReceiptNoteId
 WHERE SCPStItem_M.ManufacturerId=@MANUFCTR_ID AND cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date) 
 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPNoDiscountItemsManufacturer]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptNoDiscountItemManufacturer]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

 SELECT ManufacturerName,TTL_ITM,(TTL_ITM-NO_Discount_ITM) AS Discount_ITM,NO_Discount_ITM,(NO_Discount_ITM*100)/TTL_ITM AS NO_Discount_PRCNTG FROM 
  (
  SELECT SCPStManufactutrer.ManufacturerName,COUNT(SCPTnGoodReceiptNote_D.ItemCode) TTL_ITM,
  (SELECT COUNT(PRCD.ItemCode) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.PARENT_TRNSCTN_ID = PRCM.TRNSCTN_ID
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PRCD.ItemCode WHERE PRCD.DiscountValue=0 
  AND ITM.ManufacturerId=SCPStItem_M.ManufacturerId AND cast(PRCM.TRNSCTN_DATE as date) 
  BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)) AS NO_Discount_ITM FROM SCPTnGoodReceiptNote_D
  INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
  INNER JOIN SCPStManufactutrer ON SCPStItem_M.ManufacturerId = SCPStManufactutrer.ManufacturerId
  WHERE cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
  GROUP BY SCPStItem_M.ManufacturerId,SCPStManufactutrer.ManufacturerName
  )TMP

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPNoDiscountItemsSupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptNoDiscountItemSupplier]
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN

 SELECT SupplierLongName,TTL_ITM,(TTL_ITM-NO_Discount_ITM) AS Discount_ITM,NO_Discount_ITM,(NO_Discount_ITM*100)/TTL_ITM AS NO_Discount_PRCNTG FROM 
  (
  SELECT SCPStSupplier.SupplierLongName,COUNT(ItemCode) TTL_ITM,(SELECT COUNT(PRCD.ItemCode) FROM SCPTnGoodReceiptNote_D PRCD 
  INNER JOIN SCPTnGoodReceiptNote_M PRCM ON PRCD.PARENT_TRNSCTN_ID = PRCM.TRNSCTN_ID WHERE PRCD.DiscountValue=0 
  AND PRCM.SupplierId=SCPTnGoodReceiptNote_M.SupplierId AND cast(PRCM.TRNSCTN_DATE as date) 
  BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)) AS NO_Discount_ITM FROM SCPTnGoodReceiptNote_D
  INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
  INNER JOIN SCPStSupplier ON SCPTnGoodReceiptNote_M.SupplierId = SCPStSupplier.SupplierId
  WHERE cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
  GROUP BY SCPTnGoodReceiptNote_M.SupplierId,SCPStSupplier.SupplierLongName
  )TMP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPNoDiscountItemSupplierDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptNoDiscountItemSupplierDetail]
@FromDate as varchar(50),
@ToDate as varchar(50),
@SUPPLIER_ID as int
AS
BEGIN

 SELECT CASE WHEN SCPTnGoodReceiptNote_D.DiscountValue=0 THEN 'No Discount' ELSE 'Discounted items' END AS Discount_Status,
 SCPTnGoodReceiptNote_D.ItemCode,SCPStItem_M.ItemName,SCPTnGoodReceiptNote_D.ItemRate FROM SCPTnGoodReceiptNote_D
 INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnGoodReceiptNote_D.ItemCode
 INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId=SCPTnGoodReceiptNote_M.GoodReceiptNoteId
 WHERE SCPTnGoodReceiptNote_M.SupplierId=@SUPPLIER_ID AND cast(SCPTnGoodReceiptNote_M.GoodReceiptNoteDate as date) 
 BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPParLevelTrend]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetParLevelTrend]
@WraehouseId AS INT

AS BEGIN

DECLARE @req_start_date DateTime=CAST(DATEADD(M,-1,GETDATE()) AS date),
        @req_end_date DateTime=CAST(GETDATE() AS date)

DECLARE @userData TABLE(
    Month_Date DATETIME,
	Total_Items INT,
	Auto_Par INT,
	Manual_Par INT
);

	;WITH X AS 
		(
			SELECT @req_start_date AS VAL
			UNION ALL
			SELECT DATEADD(DD,1,VAL) FROM X
			WHERE VAL < @req_end_date
		)
	insert into @userData([Month_Date]) SELECT * FROM X


	SELECT CONVERT(VARCHAR(6),Month_Date,106) Month_Date,PAR.ITM,PAR.Manual_Par,PAR.Auto_Par,ROUND((CAST(PAR.Manual_Par AS FLOAT)/CAST(PAR.ITM AS FLOAT))*100,1) AS Man_Per FROM @userData
	OUTER APPLY(
	SELECT COUNT(CC.ItemCode) ITM,
	COUNT(CASE WHEN PLM.ParLevelType='A' THEN PLM.ParLevelType END) AS Auto_Par,
	COUNT(CASE WHEN PLM.ParLevelType='M' THEN PLM.ParLevelType END) AS Manual_Par FROM SCPStItem_M CC
	INNER JOIN SCPStParLevelAssignment_M PLM ON PLM.ItemCode = CC.ItemCode 
	AND PLM.TRNSCTN_ID=(SELECT MAX(CRM.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CRM 
	WHERE CRM.ItemCode=CC.ItemCode and CC.IsActive=1 AND FormularyId!=0 AND WraehouseId=@WraehouseId AND CRM.TRNSCTN_DATE<=Month_Date))PAR

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPartialSuppliedPO(SupplierWise)]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE[dbo].[Sp_SCPRptPartialSuppliedPODetail]
@FromDate varchar(50),
@ToDate varchar(50),
@SupId int
AS
BEGIN

SELECT SUPNAME,TRANSACTIONID, NAME,SUM(ORDERQuantity) AS ORDERQuantity, SUM(PENDINGQuantity) AS PENDINGQuantity,
SUM(X.RCVDQuantity) AS RCVDQuantity FROM(
SELECT DISTINCT SUP.SupplierLongName AS SUPNAME , PO_D.PARENT_TRNSCTN_ID AS TRANSACTIONID,CONVERT(VARCHAR(10), PO_M.TRNSCTN_DATE, 105)AS PODATE
,ITM.ItemName AS Name, OrderQty AS ORDERQuantity, PO_D.PendingQty AS PENDINGQuantity, SUM(GRN_D.RecievedQty) AS RCVDQuantity
FROM SCPTnPurchaseOrder_D PO_D INNER JOIN SCPTnPurchaseOrder_M PO_M ON PO_D.PARENT_TRNSCTN_ID = PO_M.TRNSCTN_ID
INNER JOIN SCPTnGoodReceiptNote_M GRN_M ON PO_D.PARENT_TRNSCTN_ID = GRN_M.PurchaseOrderId 
INNER JOIN  SCPTnGoodReceiptNote_D GRN_D ON GRN_D.PARENT_TRNSCTN_ID = GRN_M.TRNSCTN_ID  AND GRN_D.ItemCode = PO_D.ItemCode
INNER JOIN SCPStSupplier SUP ON PO_M.SupplierId = SUP.SupplierId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = PO_D.ItemCode
WHERE PO_D.PendingQty !=0 AND SUP.SupplierId = @SupId AND cast(PO_M.TRNSCTN_DATE as date)
BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date) 
GROUP BY PO_D.PARENT_TRNSCTN_ID,SUP.SupplierLongName,
 PO_D.OrderQty, PO_D.PendingQty,PO_M.TRNSCTN_DATE,ITM.ItemName
 )X  GROUP BY TRANSACTIONID, PODATE,NAME,SUPNAME 
ORDER BY PODATE

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPartialSuppliesAgainistPO]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPartialSuppliedPOSummary]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

SELECT SUPNAME,TRANSACTIONID,PODATE,SUM(ORDERQuantity) AS ORDERQuantity, SUM(PENDINGQuantity) AS PENDINGQuantity, SUM(X.RCVDQuantity) AS RCVDQuantity FROM(
SELECT SUP.SupplierLongName AS SUPNAME, PO_D.PARENT_TRNSCTN_ID AS TRANSACTIONID,CONVERT(VARCHAR(10), PO_M.TRNSCTN_DATE, 105)AS PODATE
--convert(varchar(10),CONVERT(date,PO_M.TRNSCTN_DATE,106),103) AS PODATE
, OrderQty AS ORDERQuantity, PO_D.PendingQty AS PENDINGQuantity, 
 SUM(GRN_D.RecievedQty) AS RCVDQuantity
FROM SCPTnPurchaseOrder_D PO_D INNER JOIN SCPTnPurchaseOrder_M PO_M ON PO_D.PARENT_TRNSCTN_ID = PO_M.TRNSCTN_ID
INNER JOIN SCPTnGoodReceiptNote_M GRN_M ON PO_D.PARENT_TRNSCTN_ID = GRN_M.PurchaseOrderId 
INNER JOIN  SCPTnGoodReceiptNote_D GRN_D ON GRN_D.PARENT_TRNSCTN_ID = GRN_M.TRNSCTN_ID  AND GRN_D.ItemCode = PO_D.ItemCode
INNER JOIN SCPStSupplier SUP ON PO_M.SupplierId = SUP.SupplierId
WHERE PO_D.PendingQty !=0 AND cast(PO_M.TRNSCTN_DATE as date)
BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date) 
GROUP BY PO_D.PARENT_TRNSCTN_ID, GRN_M.PurchaseOrderId
, PO_D.OrderQty, PO_D.PendingQty, GRN_D.ItemCode,PO_M.TRNSCTN_DATE, SUP.SupplierLongName
)X GROUP BY TRANSACTIONID, PODATE, SUPNAME 
ORDER BY PODATE
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnInPatientDetailforReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>



-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetInPatientDetail]
@PatinetIp AS VARCHAR(50)
AS
BEGIN
	 SELECT DISTINCT NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,SCPStPatientType.PatientTypeName,
	 isnull(SCPStCompany.CompanyName,'') as CompanyName FROM SCPTnSale_M 
	 INNER JOIN SCPStPatientType ON SCPTnSale_M.PatientTypeId = SCPStPatientType.PatientTypeId
	 LEFT OUTER JOIN SCPStCompany ON SCPTnSale_M.CompanyId=SCPStCompany.CompanyId
	 WHERE SCPTnSale_M.PatientIp= @PatinetIp
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnInPatientTypeWiseSaleSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPatientTypeWiseSaleSummary]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

SELECT TRANS_DT,BatchNo,UserName,PatientTypeName,OPNG_TM,SUM(SOLD) AS SOLD,SUM(RTN) AS RTN,CLSNG_TM FROM 
(
SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
SCPStPatientType.PatientTypeName,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) 
AS OPNG_TM,SUM(ROUND(Quantity*ItemRate,0)) AS SOLD,ISNULL((SELECT SUM(RTN_DTL.SaleAmount) FROM SCPTnSaleRefund_D RTN_DTL
INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) 
AND RTN_MSTR.SaleRefundId=SCPTnSale_M.SaleId  and RTN_MSTR.IsActive=1),0) AS RTN,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM
FROM SCPTnSale_M
INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId 
INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
INNER JOIN SCPStPatientType ON SCPStPatientType.PatientTypeId=SCPTnSale_M.PatientTypeId
WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
AND SCPTnSale_M.SaleId!='0' AND SCPTnSale_M.PatientIp='0'  and SCPTnSale_M.IsActive=1
GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,SCPStPatientType.PatientTypeName,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)),
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)),SCPTnSale_M.SaleId
UNION ALL	
SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
SCPStPatientType.PatientTypeName,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) 
AS OPNG_TM,SUM(ROUND(Quantity*ItemRate,0)) AS SOLD,ISNULL((SELECT SUM(RTN_DTL.SaleAmount) FROM SCPTnSaleRefund_D RTN_DTL
INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) 
AND RTN_MSTR.PatinetIp=SCPTnSale_M.PatientIp  and RTN_MSTR.IsActive=1),0) AS RTN,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM
FROM SCPTnSale_M
INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId 
INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
INNER JOIN SCPStPatientType ON SCPStPatientType.PatientTypeId=SCPTnSale_M.PatientTypeId
WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
AND SCPTnSale_M.PatientIp!='0'  and SCPTnSale_M.IsActive=1
GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,SCPStPatientType.PatientTypeName,
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)),
(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)),SCPTnSale_M.PatientIp
	)TMP GROUP BY TRANS_DT,BatchNo,UserName,PatientTypeName,OPNG_TM,CLSNG_TM
	
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPendingPO]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPendingPO]
AS
BEGIN
	SELECT DISTINCT SCPTnPurchaseOrder_M.TRNSCTN_ID,CAST(TRNSCTN_DATE AS date) AS TRANSCTN_DT,UserName,
    CASE WHEN ISNULL(IsApprove,0)=0 AND ISNULL(IsReject,0)=0 THEN 'Pending' 
    WHEN ISNULL(IsApprove,0)=1 AND ISNULL(IsReject,0)=0 THEN 'IsApproved' END AS AppStatus FROM SCPTnPurchaseOrder_M
    INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnPurchaseOrder_M.CreatedBy
    INNER JOIN SCPTnPurchaseOrder_D ON SCPTnPurchaseOrder_D.PurchaseOrderId = SCPTnPurchaseOrder_M.TRNSCTN_ID WHERE SCPTnPurchaseOrder_D.PendingQty>0
	AND IsReject=0 ORDER BY TRANSCTN_DT DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPendingPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPendingPR]
AS
BEGIN
	SELECT DISTINCT SCPTnPurchaseRequisition_M.TRANSCTN_ID,CAST(TRANSCTN_DT AS date) AS TRANSCTN_DT,UserName,
    CASE WHEN ISNULL(IsApprove,0)=0 AND ISNULL(IsReject,0)=0 THEN 'Pending' 
    WHEN ISNULL(IsApprove,0)=1 AND ISNULL(IsReject,0)=0 THEN 'IsApproved' END AS AppStatus FROM SCPTnPurchaseRequisition_M
    INNER JOIN SCPStUser_M ON SCPStUser_M.UserId=SCPTnPurchaseRequisition_M.CreatedBy
    INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID = SCPTnPurchaseRequisition_M.TRANSCTN_ID 
	WHERE SCPTnPurchaseRequisition_D.PendingQty>0 AND IsReject=0 ORDER BY TRANSCTN_DT DESC
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyDailySaleReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptDailyPharmacySale]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

 -- SELECT TRANS_DT,BatchNo,UserName,OPNG_TM,CSH_SL,CRDT_SL,CSH_RTN,CRDT_RTN,(CSH_SL-CSH_RTN) AS CSH_NET_SL,
 -- (CRDT_SL-CRDT_RTN) AS CRDT_NET_SL,CLSNG_TM FROM
 -- (
 --   SELECT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CSH_SL,
	--ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CSH_RTN,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
	--AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
 --   INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
	--LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
	--GROUP BY CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108))
 -- )TMP

 --  SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
 -- SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
 --(SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
 -- FROM
 -- (
 --   SELECT SCPTnSale_M.TRANS_DT AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
	--INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
	-- SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	--INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
	--RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId 
	--INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	--GROUP BY SCPTnSale_M.TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108))
 -- )TMP GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,UserName,OPNG_TM,CLSNG_TM


 --- COMMENTED ON 27-10-2018
--    SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
--  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
-- (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
--  FROM
--  (
--select   SCPTnBatchNo_D.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+
-- CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) AS OPNG_TM
--, SCPStUser_M.UserName,SCPTnSale_M.TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
--	SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, 
--	ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
--	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
--	 SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
--	AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
--	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
--	RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
--		(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM 
	
--	  from SCPTnBatchNo_M
--	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo 
--	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND 
--	SCPTnSale_M.CreatedBy = SCPTnBatchNo_D.UserId
--	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.UserId = SCPStUser_M.UserId 
--	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId 
--	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
--	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
--	WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)
--	AND CAST(CONVERT(date,@ToDate,103) as date)
--	GROUP BY SCPTnBatchNo_D.BatchNo,BatchStartTime, BatchCloseTime, 
--	SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnSale_M.TRANS_DT
	
--	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM, UserName ORDER BY TRANS_DT


--    SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
--  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
-- (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM 
--  FROM
--  (
--select   SCPTnBatchNo_D.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_D.StartTime, 105)+' '+
-- CONVERT(VARCHAR(5), SCPTnBatchNo_D.StartTime,108)) AS OPNG_TM
--, SCPStUser_M.UserName,SCPTnSale_M.TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
--	SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CSH_SL, 
--	ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	
--	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND
--	 SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND SL_MSTR.TRANS_DT=SCPTnSale_M.TRANS_DT),0) AS CRDT_SL,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
--	AND	RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) CSH_RTN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
--	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND 
--	RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo	AND RTN_MSTR.TRNSCTN_DATE=SCPTnSale_M.TRANS_DT),0) AS CRDT_RTN,
--		(CONVERT(VARCHAR(10), SCPTnBatchNo_D.CloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_D.CloseTime,108)) AS CLSNG_TM 
	
--	  from SCPTnBatchNo_M
--	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo 
--	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND 
--	SCPTnSale_M.CreatedBy = SCPTnBatchNo_D.UserId
--	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.UserId = SCPStUser_M.UserId 
--	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId 
--	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
--	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
--	WHERE CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,'15-09-2018',103) as date)
--	AND CAST(CONVERT(date,'20-09-2018',103) as date)
--	GROUP BY SCPTnBatchNo_D.BatchNo, SCPTnBatchNo_D.StartTime, SCPTnBatchNo_D.CloseTime,
--	SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnSale_M.TRANS_DT
	
--	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM, UserName

  SELECT CONVERT(VARCHAR(10),CreatedDate, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
  (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM FROM
   (
    select SCPTnBatchNo_M.BatchNo, (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108))
    AS OPNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL 
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 and SL_MSTR.IsActive=1 
	AND SL_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and SL_MSTR.IsActive=1),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2  and SL_MSTR.IsActive=1 
	AND SL_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and SL_MSTR.IsActive=1),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and RTN_MSTR.IsActive=1),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 and RTN_MSTR.IsActive=1 AND 
	RTN_MSTR.BatchNo=SCPTnBatchNo_M.BatchNo and RTN_MSTR.IsActive=1),0) AS CRDT_RTN,
	(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM from SCPTnBatchNo_M
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId 
	WHERE CAST(SCPTnBatchNo_M.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	GROUP BY SCPTnBatchNo_M.BatchNo,BatchStartTime, BatchCloseTime,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate
	)tmp GROUP BY CONVERT(VARCHAR(10),CreatedDate, 105),BatchNo,OPNG_TM,CLSNG_TM,UserName 

 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyPrescriptionSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPrescriptionSummary]
@FromDate VARCHAR(50),
@ToDate VARCHAR(50)
AS
BEGIN

	SET NOCOUNT ON;

 --   SELECT CONS.ConsultantName, COUNT(PHM.TRANS_ID) AS PRESCRIPTN ,SUM(PHD.Amount) AS AMOUNT
 --FROM SCPTnSale_M PHM
 -- INNER JOIN SCPStConsultant CONS ON PHM.ConsultantId = CONS.ConsultantId
 -- INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
 -- WHERE CONVERT(VARCHAR(10), TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
 -- GROUP BY CONS.ConsultantName

 
	SELECT COUNT(X.Prescription) AS PRESCRIPTN, SUM(X.Amount) AS AMOUNT, CONS.ConsultantName FROM(
		SELECT PHM.TRANS_ID AS Prescription,  SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.ConsultantId AS CONSULTANT
		FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
		WHERE CAST(PHM.TRANS_DT AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
		AND CAST(CONVERT(date,@ToDate,103) as date)  and PHM.IsActive=1
		GROUP BY PHM.TRANS_ID,  PHM.ConsultantId
	)X INNER JOIN SCPStConsultant CONS ON X.CONSULTANT = CONS.ConsultantId
GROUP BY CONS.ConsultantName
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyPrescriptionSummary_ER]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPrescriptionSummaryER]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	SELECT COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS Amount,  ER_CAT.PatientSubCategoryName AS DEPT_NAME FROM(
		SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientSubCategoryId AS SB_CAT
		FROM SCPTnSale_M PHM 
		INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
		WHERE PHM.PatientCategoryId = 3  and PHM.IsActive=1
		AND CAST(PHM.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
		GROUP BY PHM.TRANS_ID,PHM.PatientSubCategoryId
	)X INNER JOIN SCPStPatientSubCategory ER_CAT ON X.SB_CAT = ER_CAT.PatientSubCategoryId 
	GROUP BY  ER_CAT.PatientSubCategoryName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyPrescriptionSummary_SCPTnInPatientCat]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPrescriptionSummaryPatientCategoryWise]
@FromDate varchar(50),
@ToDate varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

--SELECT PT_CT.PatientCategoryName as PatientCategoryName, COUNT(PHM.TRANS_ID) AS Prescription, SUM(Amount) AS Amount FROM SCPTnSale_M PHM 
--INNER JOIN SCPStPatientCategory PT_CT ON PHM.PatientCategoryId = PT_CT.PatientCategoryId
--INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
--WHERE CONVERT(VARCHAR(10), PHM.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
--GROUP BY PT_CT.PatientCategoryName


--SELECT COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS Amount, PT_CT.PatientCategoryName  AS PatientCategoryName FROM(
--SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId
-- FROM SCPTnSale_M PHM 
----INNER JOIN SCPStPatientCategory PT_CT ON PHM.PatientCategoryId = PT_CT.PatientCategoryId
--INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
--WHERE CAST(PHM.TRANS_DT AS DATE)
--BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1
--GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId
--)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
--GROUP BY PT_CT.PatientCategoryName

--SELECT PatientCategoryName AS PatientCategoryName,COUNT(PHM.TRANS_ID) AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount
--FROM SCPTnSale_M PHM 
--INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
--INNER JOIN SCPStPatientCategory PT_CT ON PHM.PatientCategoryId = PT_CT.PatientCategoryId
--WHERE CAST(PHM.TRANS_DT AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
--AND CAST(CONVERT(date,@ToDate,103) as date) and PHM.IsActive=1
--GROUP BY PatientCategoryName


SELECT PatientCategoryName,SUM(Prescription) AS Prescription,SUM(SaleAmount)-SUM(RefundAmount) AS Amount FROM
(
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT  PT_CT.PatientCategoryName  AS PatientCategoryName,COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS SaleAmount,0 AS RefundAmount FROM(
SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId FROM SCPTnSale_M PHM 
INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
WHERE CAST(PHM.TRANS_DT AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId
)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
GROUP BY PT_CT.PatientCategoryName
)TMP GROUP BY PatientCategoryName


END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyReturnItemDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacyReturn_D]
@paramTransectionId varchar(50)
AS
BEGIN
	  SELECT ItemM.ItemCode AS ItemCode,
			 ItemM.ItemName AS ItemName,
			 PRID.BatchNo AS BatchNoBNo,
			 ItemCurrentPrice.CostPrice AS PurchasePrice,
			 ReasonId.ReasonId AS ReasonId,
			 SUM(PRID.ReturnQty) AS ReturnQty
	  FROM [dbo].[SCPTnReturnToStore_D] AS PRID
	  INNER JOIN [SCPStRate] AS ItemCurrentPrice  ON ItemCurrentPrice.ItemCode = PRID.ItemCode
	  INNER JOIN [dbo].[SCPStItem_M] AS ItemM ON ItemM.ItemCode = ItemCurrentPrice.ItemCode
	  INNER JOIN [dbo].SCPStReasonId AS ReasonId ON ReasonId.ReasonId = PRID.ReturnReasonIdId
	  WHERE PRID.PARENT_TRNSCTN_ID = @paramTransectionId AND   CAST(GETDATE() as date) BETWEEN
		  CAST(CONVERT(date,ItemCurrentPrice.FromDate,103) as date) AND 
		  CAST(CONVERT(date,ItemCurrentPrice.ToDate,103) as date) 

	  GROUP BY ItemM.ItemCode, 
			   ItemM.ItemName, 
			   PRID.BatchNo,
			   ItemCurrentPrice.CostPrice,
			   ReasonId.ReasonId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyReturnItemMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacyReturn_M]
@paramTransectionId varchar(50) 
AS
BEGIN
SELECT  PRI.TRNSCTN_ID,
	   (SELECT WraehouseName 
		FROM [dbo].[SCPStWraehouse] AS WH
		WHERE WH.WraehouseId=PRI.FromWarehouseId) AS FromWraehouseName,
	   (SELECT WraehouseName 
	    FROM [dbo].[SCPStWraehouse] AS WH
	    WHERE WH.WraehouseId=PRI.ToWarehouseId) AS ToWraehouseName,
		PRI.CreatedDate AS CreatedOn 
		FROM [dbo].[SCPTnReturnToStore_M] AS PRI
		WHERE PRI.TRNSCTN_ID = @paramTransectionId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacySaleLabel]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySaleLabel]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT PatientIp,(SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName) AS SCPTnInPatient_NAME,ItemName,Quantity,SignaName,SignaLabel,UserName FROM SCPTnSale_M
	INNER JOIN SCPTnInPatient ON SCPTnInPatient.PatientIp=SCPTnSale_M.PatientIp
	INNER JOIN SCPTnSale_D ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
	INNER JOIN SCPStItem_M ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
	INNER JOIN SCPStSigna ON SCPTnSale_D.SignaId = SCPStSigna.SignaId
	INNER JOIN SCPTnBatchNo_M ON SCPTnSale_M.BatchNo = SCPTnBatchNo_M.BatchNo
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId
	WHERE SCPTnSale_M.SaleId=@TRNSCTN_ID 

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacySaleReportUserWise]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySaleUserWise]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50)
AS
BEGIN

 -- SELECT TRANS_DT,BatchNo,UserName,OPNG_TM,CSH_SL,CRDT_SL,CSH_RTN,CRDT_RTN,(CSH_SL-CSH_RTN) AS CSH_NET_SL,
 -- (CRDT_SL-CRDT_RTN) AS CRDT_NET_SL,CLSNG_TM FROM
 -- (
 --   SELECT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) AS OPNG_TM,
	--ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo AND 
	--CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CSH_SL,
	--ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	--SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_SL,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo 
	--AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CSH_RTN,
	--ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	--RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo
	--AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CRDT_RTN,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM 
	--FROM SCPTnSale_M INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
 --   INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
	--LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo
	--LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	--WHERE CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) BETWEEN @FromDate AND @ToDate
	--GROUP BY CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),SCPTnSale_M.BatchNo,SCPStUser_M.UserName,
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)),
	--(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108))
 -- )TMP


   SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) AS TRANS_DT,BatchNo,UserName,OPNG_TM,SUM(CSH_SL) AS CSH_SL,
  SUM(CRDT_SL) AS CRDT_SL,SUM(CSH_RTN) AS CSH_RTN,SUM(CRDT_RTN) AS CRDT_RTN,(SUM(CSH_SL)-SUM(CSH_RTN)) AS CSH_NET_SL,
 (SUM(CRDT_SL)-SUM(CRDT_RTN)) AS CRDT_NET_SL,CLSNG_TM FROM
  (
  select SCPTnBatchNo_D.BatchNo,-- (CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchStartTime, 105)+' '+CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchStartTime,108)) AS OPNG_TM,
  (select TOP 1 (CONVERT(VARCHAR(10), CreatedDate, 105)+' '+CONVERT(VARCHAR(5),CreatedDate,108)) from SCPTnBatchNo_D PHD where BatchNo=SCPTnBatchNo_D.BatchNo 
   AND PHD.UserId=SCPTnBatchNo_D.UserId) as OPNG_TM,(select TOP 1 (CONVERT(VARCHAR(10), CloseTime, 105)+' '+CONVERT(VARCHAR(5),CloseTime,108)) from SCPTnBatchNo_D PHD
   where BatchNo=SCPTnBatchNo_D.BatchNo AND PHD.UserId=SCPTnBatchNo_D.UserId) as CLSNG_TM,SCPStUser_M.UserName,SCPTnBatchNo_M.CreatedDate as TRANS_DT,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0))
    FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo and SL_MSTR.IsActive=1 
	AND SL_MSTR.CreatedBy=SCPTnBatchNo_D.UserId and SL_MSTR.IsActive=1),0) AS CSH_SL,ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	
	INNER JOIN SCPTnSale_M SL_MSTR ON SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.BatchNo=SCPTnSale_M.BatchNo  and SL_MSTR.IsActive=1 
	AND SL_MSTR.CreatedBy=SCPTnBatchNo_D.UserId and SL_MSTR.IsActive=1),0) AS CRDT_SL,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.CreatedBy=SCPTnBatchNo_D.UserId and RTN_MSTR.IsActive=1),0) CSH_RTN,ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL 
	INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2 AND RTN_MSTR.BatchNo=SCPTnSale_M.BatchNo and RTN_MSTR.IsActive=1 
	AND RTN_MSTR.CreatedBy=SCPTnBatchNo_D.UserId and RTN_MSTR.IsActive=1),0) AS CRDT_RTN --,(CONVERT(VARCHAR(10), SCPTnBatchNo_M.BatchCloseTime, 105)+' '+ CONVERT(VARCHAR(5),SCPTnBatchNo_M.BatchCloseTime,108)) AS CLSNG_TM
	 from SCPTnBatchNo_M
	INNER JOIN SCPTnBatchNo_D ON SCPTnBatchNo_M.BatchNo = SCPTnBatchNo_D.BatchNo AND SCPTnBatchNo_M.IsActive=1
	LEFT OUTER JOIN SCPTnSale_M ON SCPTnBatchNo_D.BatchNo = SCPTnSale_M.BatchNo AND SCPTnSale_M.CreatedBy = SCPTnBatchNo_D.UserId AND SCPTnSale_M.IsActive=1
	INNER JOIN SCPStUser_M ON SCPTnBatchNo_D.UserId = SCPStUser_M.UserId 
	LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId  
	LEFT OUTER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_M.BatchNo = SCPTnSale_M.BatchNo AND SCPTnSaleRefund_M.IsActive=1
	LEFT OUTER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID
	WHERE CAST(SCPTnBatchNo_M.CreatedDate as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	GROUP BY SCPTnBatchNo_D.BatchNo,BatchStartTime, BatchCloseTime,SCPStUser_M.UserName, SCPTnSale_M.BatchNo, SCPTnBatchNo_M.CreatedDate,SCPTnBatchNo_D.UserId
	)tmp GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),BatchNo,OPNG_TM,CLSNG_TM,UserName ORDER BY TRANS_DT

  END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacySales]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySales]
	@IP as varchar(50),
	@SL as varchar(50)


AS
BEGIN
	SET NOCOUNT ON;

IF (@IP !='0')
SELECT *, CASE WHEN CAREOFBY = 'Consultant' THEN (SELECT TOP 1 CONS.ConsultantName FROM  SCPStConsultant CONS 
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = CONS.ConsultantId WHERE SCPTnSale_M.PatientIp = @IP )
WHEN  CAREOFBY = 'Employee' THEN (SELECT TOP 1 EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = EMP.EmployeeCode WHERE SCPTnSale_M.PatientIp = @IP )
WHEN CAREOFBY = 'Partner' THEN (SELECT TOP 1 PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = PART.PartnerId WHERE SCPTnSale_M.PatientIp = @IP  )
END AS CARECODE FROM(
SELECT SM.TRANS_ID, TRANS_DT, PatientIp, (SM.NamePrefix+'.'+SM.FirstName+' '+SM.LastName) as [PTName] 
, PAT.RoomNo, PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, PAT_SBCAT.PatientSubCategoryName, CONS.ConsultantName, 
CMP.CompanyName, PAYMENT.PaymentTermName, e.UserName, SM.BatchNo, SD.Duration,
CASE WHEN SM.CareOffCode = 1 THEN 'Employee'
     WHEN SM.CareOffCode= 2 THEN 'Consultant'
	 WHEN SM.CareOffCode =3 THEN 'Partner'
	 end AS CAREOFBY, SD.Pneumonics, SD.ItemCode, ITM.ItemName, SD.STOCK, SD.DOSE,(SELECT TOP 1 SIG.SignaName FROM SCPTnSale_D SD 
	 INNER JOIN SCPStSigna SIG ON SIG.SignaQuantity = SD.SignaId) AS SIGNA, SD.ItemRate, SD.Quantity,SM.ReceivedAmount FROM SCPTnSale_M SM 
LEFT OUTER JOIN SCPTnInPatient PAT ON PAT.PatientIp = SM.PatientIp
INNER JOIN SCPStPatientType PAT_TYPE ON PAT_TYPE.PatientTypeId = SM.PatientTypeId 
INNER JOIN SCPStPatientCategory PAT_CAT ON PAT_CAT.PatientCategoryId = SM.PatientCategoryId
INNER JOIN SCPStPatientSubCategory PAT_SBCAT ON PAT_SBCAT.PatientSubCategoryId = sm.PatientSubCategoryId
LEFT OUTER JOIN  SCPStConsultant CONS ON  CONS.ConsultantId = SM.ConsultantId
LEFT OUTER JOIN  SCPStCompany CMP ON CMP.CompanyId = SM.CompanyId
INNER JOIN SCPStUser_M e on SM.CreatedBy=e.UserId
INNER JOIN SCPTnSale_D SD ON SD.PARNT_TRANS_ID = SM.TRANS_ID
INNER JOIN SCPStPaymentTerm PAYMENT ON PAYMENT.PaymentTermId= SD.PaymentTermId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SD.ItemCode

WHERE SM.PatientIp = @IP 
GROUP BY SM.TRANS_ID,TRANS_DT, PatientIp, (SM.NamePrefix+'.'+SM.FirstName+' '+SM.LastName)  
, PAT.RoomNo, PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, PAT_SBCAT.PatientSubCategoryName, CONS.ConsultantName, 
CMP.CompanyName, PAYMENT.PaymentTermName, SM.CareOffCode, SD.Pneumonics, SD.ItemCode, ITM.ItemName, SD.STOCK,
 SD.DOSE, SD.ItemRate, SD.Quantity,SD.SignaId,SM.ReceivedAmount,e.UserName, SM.BatchNo,SD.Duration
 )X

 IF (@SL !='0')
 SELECT *, CASE WHEN CAREOFBY = 'Consultant' THEN (SELECT TOP 1 CONS.ConsultantName FROM  SCPStConsultant CONS 
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = CONS.ConsultantId WHERE SCPTnSale_M.SaleId = @SL )
WHEN  CAREOFBY = 'Employee' THEN (SELECT TOP 1 EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = EMP.EmployeeCode WHERE SCPTnSale_M.SaleId = @SL )
WHEN CAREOFBY = 'Partner' THEN (SELECT TOP 1 PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = PART.PartnerId WHERE SCPTnSale_M.SaleId = @SL  )
END AS CARECODE FROM(
SELECT SM.TRANS_ID, TRANS_DT, PatientIp, (SM.NamePrefix+'.'+SM.FirstName+' '+SM.LastName) as [PTName] 
, PAT.RoomNo, PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, PAT_SBCAT.PatientSubCategoryName, CONS.ConsultantName, 
CMP.CompanyName, PAYMENT.PaymentTermName, e.UserName, SM.BatchNo, SD.Duration,
CASE WHEN SM.CareOffCode = 1 THEN 'Employee'
     WHEN SM.CareOffCode= 2 THEN 'Consultant'
	 WHEN SM.CareOffCode =3 THEN 'Partner'
	 end AS CAREOFBY, SD.Pneumonics, SD.ItemCode, ITM.ItemName, SD.STOCK, SD.DOSE,(SELECT TOP 1 SIG.SignaName FROM SCPTnSale_D SD 
	 INNER JOIN SCPStSigna SIG ON SIG.SignaQuantity = SD.SignaId) AS SIGNA, SD.ItemRate, SD.Quantity,SM.ReceivedAmount FROM SCPTnSale_M SM 
LEFT OUTER JOIN SCPTnInPatient PAT ON PAT.PatientIp = SM.PatientIp
INNER JOIN SCPStPatientType PAT_TYPE ON PAT_TYPE.PatientTypeId = SM.PatientTypeId 
INNER JOIN SCPStPatientCategory PAT_CAT ON PAT_CAT.PatientCategoryId = SM.PatientCategoryId
INNER JOIN SCPStPatientSubCategory PAT_SBCAT ON PAT_SBCAT.PatientSubCategoryId = sm.PatientSubCategoryId
LEFT OUTER JOIN  SCPStConsultant CONS ON  CONS.ConsultantId = SM.ConsultantId
LEFT OUTER JOIN  SCPStCompany CMP ON CMP.CompanyId = SM.CompanyId
INNER JOIN SCPStUser_M e on SM.CreatedBy=e.UserId
INNER JOIN SCPTnSale_D SD ON SD.PARNT_TRANS_ID = SM.TRANS_ID
INNER JOIN SCPStPaymentTerm PAYMENT ON PAYMENT.PaymentTermId= SD.PaymentTermId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SD.ItemCode

WHERE SM.TRANS_ID = @SL 
GROUP BY SM.TRANS_ID,TRANS_DT, PatientIp, (SM.NamePrefix+'.'+SM.FirstName+' '+SM.LastName)  
, PAT.RoomNo, PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, PAT_SBCAT.PatientSubCategoryName, CONS.ConsultantName, 
CMP.CompanyName, PAYMENT.PaymentTermName, SM.CareOffCode, SD.Pneumonics, SD.ItemCode, ITM.ItemName, SD.STOCK,
 SD.DOSE, SD.ItemRate, SD.Quantity,SD.SignaId,SM.ReceivedAmount,e.UserName, SM.BatchNo,SD.Duration
 )X

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacySalesReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Tabish Tahir>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySaleSlip]
@InvoiceNumber as varchar(50)
AS
BEGIN

SELECT * , CASE WHEN PatientIp = '0' THEN ' ' ELSE PatientIp END AS IP ,
CASE WHEN PatientTypeName = 'Corporate' THEN (SELECT 'Corp' + ' ' + COMP.CompanyName FROM SCPStCompany COMP LEFT OUTER JOIN SCPTnSale_M 
ON COMP.CompanyId = SCPTnSale_M.CompanyId WHERE SCPTnSale_M.SaleId = @InvoiceNumber) 
WHEN PatientTypeName = 'Private' AND CareOffCode=0 THEN 'Private' 
WHEN PatientTypeName = 'Private' AND CareOffCode = 1 THEN (SELECT TOP 1 'C/O' + ' ' +'Employee' + ' ' + EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = EMP.EmployeeCode WHERE SCPTnSale_M.SaleId = @InvoiceNumber)
WHEN PatientTypeName = 'Private' AND CareOffCode = 2 THEN (SELECT TOP 1 'C/O' + ' ' +'Consultant' + ' ' + CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = CONS.ConsultantId WHERE SCPTnSale_M.SaleId = @InvoiceNumber)
WHEN PatientTypeName = 'Private' AND CareOffCode = 3 THEN (SELECT  TOP 1 'C/O' + ' ' +'Partner' + ' ' +  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = PART.PartnerId WHERE SCPTnSale_M.SaleId = @InvoiceNumber)
 END AS CARECODE
FROM (
SELECT a.TRANS_ID, a.PatientIp , a.CreatedDate as TRANS_DT ,
(a.NamePrefix+'. '+a.FirstName+' '+a.LastName) as [PTName],
b.PatientTypeName ,d.ItemName ,a.CreatedBy, F.PaymentTermName as ModeOfPaymentId,
MAX(c.PRICE)AS PRICE ,SUM(c.Quantity) AS Quantity, a.BatchNo,SUM(ROUND(Quantity*ItemRate,0)) Amount,e.UserName,ReceivedAmount, A.CareOffCode
FROM SCPTnSale_M as a 
INNER JOIN SCPStPatientType b on a.PatientTypeId = b.PatientTypeId 
INNER JOIN SCPTnSale_D c on a.TRANS_ID = c.PARNT_TRANS_ID 
INNER JOIN SCPStItem_M d on c.ItemCode = d.ItemCode
INNER JOIN SCPStUser_M e on a.CreatedBy=e.UserId
INNER JOIN SCPStPaymentTerm F ON  F.PaymentTermId = C.PaymentTermId
WHERE a.TRANS_ID = @InvoiceNumber
GROUP BY a.TRANS_ID  ,a.PatientIp ,a.CreatedDate ,
(a.NamePrefix+'. '+a.FirstName+' '+a.LastName),
b.PatientTypeName ,d.ItemName ,a.CreatedBy, a.BatchNo,e.UserName,ReceivedAmount, F.PaymentTermName, A.CareOffCode
)X
--SELECT TRANS_ID,PatientIp,TRANS_DT,PTName,PatientTypeName,ItemName,CreatedBy,ModeOfPaymentId,PRICE,Quantity,BatchNo,Amount,UserName,ReceivedAmount,CareOffCode,
--CASE WHEN PatientIp = '0' THEN ' ' ELSE PatientIp END AS IP,CASE WHEN PatientTypeName = 'Private' THEN 'Private' 
--WHEN PatientTypeName = 'Corporate' THEN (SELECT 'Corp' + ' ' + COMP.CompanyName FROM SCPStCompany COMP 
--LEFT OUTER JOIN SCPTnSale_M ON COMP.CompanyId = SCPTnSale_M.CompanyId WHERE SCPTnSale_M.SaleId = @InvoiceNumber) 
--WHEN CareOffCode = 1 THEN (SELECT TOP 1 'C/O' + ' ' +'Employee' + ' ' + EMP.EmployeeName FROM SCPStEmployee EMP
--INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = EMP.EmployeeCode WHERE SCPTnSale_M.SaleId = @InvoiceNumber)
--WHEN CareOffCode = 2 THEN (SELECT TOP 1 'C/O' + ' ' +'Consultant' + ' ' + CONS.ConsultantName FROM SCPStConsultant CONS
--INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = CONS.ConsultantId WHERE SCPTnSale_M.SaleId = @InvoiceNumber)
--WHEN CareOffCode = 3 THEN (SELECT  TOP 1 'C/O' + ' ' +'Partner' + ' ' +  PART.PartnerName FROM SCPStPartner PART
--INNER JOIN SCPTnSale_M ON SCPTnSale_M.CareOff = PART.PartnerId WHERE SCPTnSale_M.SaleId = @InvoiceNumber) END AS CARECODE
--FROM (
--SELECT a.TRANS_ID, C.TRANS_ID AS CHILD_ID,a.PatientIp , a.CreatedDate as TRANS_DT ,
--(a.NamePrefix+'. '+a.FirstName+' '+a.LastName) as [PTName],
--b.PatientTypeName ,d.ItemName ,a.CreatedBy, F.PaymentTermName as ModeOfPaymentId,
--MAX(c.PRICE)AS PRICE ,SUM(c.Quantity) AS Quantity, a.BatchNo,c.Amount,e.UserName,ReceivedAmount, A.CareOffCode
--FROM SCPTnSale_M as a 
--INNER JOIN SCPStPatientType b on a.PatientTypeId = b.PatientTypeId 
--INNER JOIN SCPTnSale_D c on a.TRANS_ID = c.PARNT_TRANS_ID 
--INNER JOIN SCPStItem_M d on c.ItemCode = d.ItemCode
--INNER JOIN SCPStUser_M e on a.CreatedBy=e.UserId
--INNER JOIN SCPStPaymentTerm F ON  F.PaymentTermId = C.PaymentTermId
--WHERE a.TRANS_ID = @InvoiceNumber
--GROUP BY a.TRANS_ID ,C.TRANS_ID ,a.PatientIp ,a.CreatedDate,(a.NamePrefix+'. '+a.FirstName+' '+a.LastName),
--b.PatientTypeName ,d.ItemName ,a.CreatedBy, a.BatchNo,c.Amount,e.UserName,ReceivedAmount, F.PaymentTermName, A.CareOffCode
--)X ORDER BY CHILD_ID

 END





GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacySalesSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySalesSummary]
@Fromdate varchar(50),
@Todate varchar(50)
AS
BEGIN

SELECT CONVERT(VARCHAR(10),TRANS_DT, 105) as TRANS_DT ,SUM(PVT_SCPTnInPatientS) as PVT_SCPTnInPatientS,SUM(CORP_SCPTnInPatientS) as CORP_SCPTnInPatientS,
SUM(MEDICINE) AS MEDICINE , SUM (CASHSALE) as CASHSALE, SUM(CREDITSALE) as CREDITSALE,SUM(CASHRETURN) as CASHRETURN,
SUM(CREDITRETURN) as CREDITRETURN,SUM((CASHSALE-CASHRETURN)) AS NETCASH, SUM((CREDITSALE-CREDITRETURN) )AS NETCREDIT,
SUM(((CASHSALE-CASHRETURN) +  CREDITSALE - CREDITRETURN)) AS NETTOTAL FROM (
	SELECT (SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
	WHERE CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date) AND 
	SL_MSTR.PatientTypeId=2 AND SL_MSTR.PatientIp = '0')AS CORP_SCPTnInPatientS,
	(SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
	WHERE  CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date) 
	AND SL_MSTR.PatientTypeId=1 AND SL_MSTR.PatientIp = '0')AS PVT_SCPTnInPatientS,
	SUM(Quantity) AS MEDICINE,  CAST(TRANS_DT as date) AS TRANS_DT,
	ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
	SL_MSTR.TRANS_ID = SL_DTL.PARNT_TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.PatientIp = '0' and SL_MSTR.IsActive=1 AND 
	CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CASHSALE,
	ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.PatientIp = '0' and SL_MSTR.IsActive=1 
	AND CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CREDITSALE,
	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	AND RTN_MSTR.PatinetIp = '0' and RTN_MSTR.IsActive=1 
	AND CAST(RTN_MSTR.TRNSCTN_DATE as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) CASHRETURN,
	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.PatinetIp = '0' and RTN_MSTR.IsActive=1 
	AND CAST(RTN_MSTR.TRNSCTN_DATE as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CREDITRETURN FROM SCPTnSale_M 
	INNER JOIN SCPTnSale_D PSD ON SCPTnSale_M.SaleId = PSD.PARNT_TRANS_ID
	WHERE SCPTnSale_M.PatientIp = '0' and  CAST(SCPTnSale_M.TRANS_DT as date) 
	BETWEEN cast(CONVERT(date,@Fromdate,103) as date)  AND cast(CONVERT(datetime,@Todate,103) as date)
	GROUP BY  CAST(TRANS_DT as date)
	UNION ALL 
SELECT (SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
	WHERE  CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date) 
	AND SL_MSTR.PatientTypeId=2 AND SL_MSTR.PatientIp != '0')AS CORP_SCPTnInPatientS,
	(SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
	WHERE CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date) 
	AND SL_MSTR.PatientTypeId=1 AND SL_MSTR.PatientIp != '0')AS PVT_SCPTnInPatientS,
	SUM(Quantity) AS MEDICINE,  CAST(TRANS_DT as date) AS TRANS_DT,
	ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 AND SL_MSTR.PatientIp != '0' and SL_MSTR.IsActive=1 AND
	CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CASHSALE,
	ISNULL((SELECT SUM(ROUND(SL_DTL.Quantity*SL_DTL.PRICE,0)) FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND SL_MSTR.PatientIp != '0' and SL_MSTR.IsActive=1
	AND  CAST(SL_MSTR.TRANS_DT as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CREDITSALE,
	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1 AND RTN_MSTR.PatinetIp != '0' and RTN_MSTR.IsActive=1 
	AND CAST(RTN_MSTR.TRNSCTN_DATE as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) CASHRETURN,
	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	AND RTN_MSTR.PatinetIp != '0' and RTN_MSTR.IsActive=1 
	AND CAST(RTN_MSTR.TRNSCTN_DATE as date) = CAST(SCPTnSale_M.TRANS_DT  as date)),0) AS CREDITRETURN FROM SCPTnSale_M 
	INNER JOIN SCPTnSale_D PSD ON SCPTnSale_M.SaleId = PSD.PARNT_TRANS_ID
	WHERE SCPTnSale_M.PatientIp != '0'and  CAST(SCPTnSale_M.TRANS_DT as date) 
	BETWEEN cast(CONVERT(date,@Fromdate,103) as date)  AND cast(CONVERT(datetime,@Todate,103) as date)
	GROUP BY  CAST(TRANS_DT as date)
)X 
GROUP BY CONVERT(VARCHAR(10),TRANS_DT, 105),cast(TRANS_DT as date) order by CONVERT(VARCHAR(10),TRANS_DT, 105)
--  SELECT TRANS_DT,SCPTnInPatientS,SUM(MEDICINE) AS MEDICINE ,CASHSALE,CREDITSALE,CASHRETURN,CREDITRETURN,(CASHSALE-CASHRETURN) AS NETCASH,
--  (CREDITSALE-CREDITRETURN) AS NETCREDIT, ((CASHSALE-CASHRETURN) +  CREDITSALE - CREDITRETURN) AS NETTOTAL
--FROM (
--SELECT (SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
-- WHERE CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)) AS SCPTnInPatientS,
--  SUM(Quantity) AS MEDICINE, CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND 
--	CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CASHSALE,
--		ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 
--	AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CREDITSALE,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	
--	AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CASHRETURN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	
--	AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CREDITRETURN
-- FROM SCPTnSale_M 
--INNER JOIN SCPTnSale_D PSD ON SCPTnSale_M.SaleId = PSD.PARNT_TRANS_ID

-- WHERE SCPTnSale_M.PatientIp = '0'
-- GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)

-- UNION ALL 
-- SELECT (SELECT COUNT(SL_MSTR.TRANS_ID) TRANS_ID FROM SCPTnSale_M SL_MSTR 
-- WHERE CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)) AS SCPTnInPatientS,
--  SUM(Quantity) AS MEDICINE, CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,
--	ISNULL((SELECT SUM(SL_DTL.Amount) FROM SCPTnSale_D SL_DTL INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=2 AND 
--	CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CASHSALE,
--		ISNULL((SELECT SUM(SL_DTL.Amount) CSH_SL FROM SCPTnSale_D SL_DTL	INNER JOIN SCPTnSale_M SL_MSTR ON 
--	SL_DTL.PARNT_TRANS_ID=SL_MSTR.TRANS_ID WHERE SL_DTL.PaymentTermId=1 
--	AND CONVERT(VARCHAR(10), SL_MSTR.TRANS_DT, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CREDITSALE,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=2	
--	AND	CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) CASHRETURN,
--	ISNULL((SELECT SUM(RTN_DTL.ReturnAmount) FROM SCPTnSaleRefund_D RTN_DTL INNER JOIN SCPTnSaleRefund_M RTN_MSTR ON 
--	RTN_DTL.PARENT_TRNSCTN_ID=RTN_MSTR.TRNSCTN_ID WHERE RTN_DTL.PaymentTermId=1	
--	AND CONVERT(VARCHAR(10), RTN_MSTR.TRNSCTN_DATE, 105)=CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)),0) AS CREDITRETURN

-- FROM SCPTnSale_M 
--INNER JOIN SCPTnSale_D PSD ON SCPTnSale_M.SaleId = PSD.PARNT_TRANS_ID
-- WHERE SCPTnSale_M.PatientIp != '0'

-- GROUP BY  CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105)
-- )X 
--  WHERE TRANS_DT BETWEEN @Fromdate AND @Todate
--  GROUP BY CASHSALE,CREDITSALE,CASHRETURN,CREDITRETURN, TRANS_DT,SCPTnInPatientS
--  ORDER BY TRANS_DT


--SELECT Convert(varchar(10),TRANS_DT,105) AS TRANS_DT,SUM(SCPTnInPatientS) AS SCPTnInPatientS, SUM(MEDICINE) AS MEDICINE
--, SUM(CASHSALE) AS CASHSALE, SUM(CASHRETURN) AS CASHRETURN ,
-- SUM(CREDITSALE) AS CREDITSALE, SUM(CREDITRETURN)  AS CREDITRETURN,
-- (SUM(CASHSALE)-SUM(CASHRETURN)) AS NETCASH, (SUM(CREDITSALE)- SUM(CREDITRETURN)) AS NETCREDIT,
--  (SUM(CASHSALE)-SUM(CASHRETURN)  +  SUM(CREDITSALE)- SUM(CREDITRETURN)) AS NETTOTAL
--FROM (

--SELECT Convert(date,PSM.TRANS_DT) AS TRANS_DT ,COUNT(PSM.TRANS_ID) AS SCPTnInPatientS, SUM(Quantity) AS MEDICINE,
--CASE WHEN PaymentTermId = 2 THEN SUM(Amount) ELSE 0 END  AS CASHSALE,
--CASE WHEN PaymentTermId = 1 THEN SUM(Amount) ELSE 0 END AS CREDITSALE,
--CASE WHEN PaymentTermId= 2 THEN SUM(ReturnAmount) ELSE 0 END AS CASHRETURN,
--CASE WHEN PaymentTermId = 1 THEN SUM(ReturnAmount) ELSE 0 END AS CREDITRETURN
-- FROM SCPTnSale_M PSM

--LEFT OUTER JOIN SCPTnSaleRefund_M PRM ON PSM.TRANS_ID = PRM.SaleRefundId
-- INNER JOIN SCPTnSale_D PSD ON PSM.TRANS_ID = PSD.PARNT_TRANS_ID
--LEFT OUTER JOIN SCPTnSaleRefund_D PRD ON PRM.TRNSCTN_ID = PRD.PARENT_TRNSCTN_ID
-- WHERE PSM.PatientIp = '0'
-- GROUP BY TRANS_DT, PSD.PaymentTermId, PRD.PaymentTermId

-- UNION ALL 
-- SELECT Convert(date,PSM.TRANS_DT) AS TRANS_DT, COUNT(PSM.PatientIp) AS SCPTnInPatientS, SUM(Quantity) AS MEDICINE,
--CASE WHEN PaymentTermId = 2 THEN SUM(Amount) ELSE 0 END  AS CASHSALE,
--CASE WHEN PaymentTermId = 1 THEN SUM(Amount) ELSE 0 END AS CREDITSALE,
--CASE WHEN PaymentTermId= 2 THEN SUM(ReturnAmount) ELSE 0 END AS CASHRETURN,
--CASE WHEN PaymentTermId = 1 THEN SUM(ReturnAmount) ELSE 0 END AS CREDITRETURN
-- FROM SCPTnSale_M PSM

--LEFT OUTER JOIN SCPTnSaleRefund_M PRM ON PSM.PatientIp= PRM.PatinetIp
-- INNER JOIN SCPTnSale_D PSD ON PSM.TRANS_ID = PSD.PARNT_TRANS_ID
--LEFT OUTER JOIN SCPTnSaleRefund_D PRD ON PRM.TRNSCTN_ID = PRD.PARENT_TRNSCTN_ID
-- WHERE PSM.PatientIp !='0'
-- GROUP BY TRANS_DT, PSD.PaymentTermId, PRD.PaymentTermId
-- )X 
--  WHERE Convert(varchar(10),TRANS_DT,105)BETWEEN @Fromdate AND @Todate
--   GROUP BY Convert(varchar(10),TRANS_DT,105)




END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPharmacyStockReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacyStock]
@FromDate AS VARCHAR(50),
@ToDate AS VARCHAR(50),
@ItemDesc AS VARCHAR(MAX)
AS
BEGIN
 --   SELECT SCPStItem_M.ItemCode,ItemName,DosageName,StrengthIdName,ISNULL((SELECT TOP 1 SCPTnStock_D.CurrentStock FROM SCPTnStock_D 
	--WHERE CAST(CreatedDate AS DATE)	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND 
	--CAST(CONVERT(date,@ToDate,103) as date) AND ItemCode=SCPStItem_M.ItemCode AND WraehouseId=3 
	--ORDER BY CreatedDate DESC),0) AS OpeningClose,ISNULL((SELECT SUM(IssueQty) FROM SCPTnPharmacyIssuance_D
	--WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS ISSUED_QTY,ISNULL((SELECT SUM(Quantity) FROM SCPTnSale_D 
	--WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS SOLD_QTY,ISNULL((SELECT SUM(ReturnQty) FROM SCPTnSaleRefund_D 
	--WHERE ItemCode=SCPStItem_M.ItemCode AND CAST(CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS ReturnQty,ISNULL((SELECT SUM(SCPTnItemDiscard_D.Quantity) FROM SCPTnItemDiscard_D 
	--INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=3 
	--AND DIscardType=2 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DAMAGED,ISNULL((SELECT SUM(SCPTnItemDiscard_D.Quantity) FROM SCPTnItemDiscard_D 
	--INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=3
	--AND DIscardType=2 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	--AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS EXPIRED,SUM(CurrentStock) AS CurrentStock,SCPStRate.CostPrice,
	--(SUM(CurrentStock)*SCPStRate.CostPrice) AS STOCK_VALUE FROM SCPStItem_M
	--INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
	--INNER JOIN SCPStStrengthId ON SCPStStrengthId.StrengthIdId = SCPStItem_M.StrengthId
	--INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=3
	--INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	--FROM SCPStRate CPP WHERE GETDATE() BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
	--WHERE SCPStItem_M.ItemName LIKE '%'+@ItemDesc+'%'
	--GROUP BY SCPStItem_M.ItemCode,ItemName,DosageName,StrengthIdName,SCPStRate.CostPrice ORDER BY SCPStItem_M.ItemCode

	SELECT SCPStItem_M.ItemCode,ItemName,DosageName,StrengthIdName,SCPTnStock_M.BatchNo,ISNULL((SELECT TOP 1 SCPTnStock_D.ItemBalance 
    FROM SCPTnStock_D WHERE ItemCode=SCPStItem_M.ItemCode AND WraehouseId=3 AND BatchNo=SCPTnStock_M.BatchNo 
    AND CAST(CreatedDate as date) < CAST(CONVERT(date,@FromDate,103) as date) 
	ORDER BY CreatedDate desc),0) AS OpeningClose,ISNULL((SELECT SUM(SCPTnStock_D.ItemPackingQuantity) FROM SCPTnPharmacyIssuance_D 
	INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=SCPTnPharmacyIssuance_M.TRNSCTN_ID 
	INNER JOIN SCPTnStock_D ON SCPTnStock_D.TransactionDocumentId = SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID AND SCPTnStock_D.ItemCode=SCPTnPharmacyIssuance_D.ItemCode
	WHERE SCPTnPharmacyIssuance_D.ItemCode=SCPStItem_M.ItemCode AND SCPTnStock_D.BatchNo=SCPTnStock_M.BatchNo AND CAST(SCPTnPharmacyIssuance_M.CreatedDate AS DATE)
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date) 
	AND SCPTnStock_D.WraehouseId=3),0) AS ISSUED_QTY,ISNULL((SELECT SUM(Quantity) FROM SCPTnSale_D WHERE ItemCode=SCPStItem_M.ItemCode 
	AND SCPTnSale_D.BatchNo=SCPTnStock_M.BatchNo AND CAST(CreatedDate AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date)  and SCPTnSale_D.IsActive=1),0) AS SOLD_QTY,
	ISNULL((SELECT SUM(ReturnQty) FROM SCPTnSaleRefund_D WHERE ItemCode=SCPStItem_M.ItemCode AND SCPTnSaleRefund_D.BatchNo=SCPTnStock_M.BatchNo 
	AND CAST(CreatedDate AS DATE)	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) and SCPTnSaleRefund_D.IsActive=1),0) AS ReturnQty,
	ISNULL((SELECT SUM(SCPTnItemDiscard_D.Quantity) FROM SCPTnItemDiscard_D 
	INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID WHERE SCPTnItemDiscard_D.ItemCode=SCPStItem_M.ItemCode 
	AND SCPTnItemDiscard_D.BatchNo=SCPTnStock_M.BatchNo AND WraehouseId=3 AND DIscardType=2 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS DAMAGED,
	ISNULL((SELECT SUM(SCPTnItemDiscard_D.Quantity) FROM SCPTnItemDiscard_D 
	INNER JOIN SCPTnItemDiscard_M ON SCPTnItemDiscard_D.PARENT_TRANS_ID = SCPTnItemDiscard_M.TRANSC_ID WHERE SCPTnItemDiscard_D.ItemCode=SCPStItem_M.ItemCode
	AND SCPTnItemDiscard_D.BatchNo=SCPTnStock_M.BatchNo AND WraehouseId=3 AND DIscardType=2 AND CAST(SCPTnItemDiscard_M.CreatedDate AS DATE)
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)),0) AS EXPIRED,
	CurrentStock,SCPStRate.CostPrice,(CurrentStock*(CASE WHEN SCPTnGoodReceiptNote_D.ItemRate IS NULL THEN SCPStRate.CostPrice 
	ELSE SCPTnGoodReceiptNote_D.ItemRate END)) AS STOCK_VALUE FROM SCPStItem_M
	INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
	INNER JOIN SCPStStrengthId ON SCPStStrengthId.StrengthIdId = SCPStItem_M.StrengthId
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=3
	LEFT OUTER JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode = SCPTnStock_M.ItemCode AND SCPTnStock_M.BatchNo = SCPTnGoodReceiptNote_D.BatchNo
	AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D WHERE SCPTnGoodReceiptNote_D.ItemCode = SCPTnStock_M.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = SCPTnStock_M.BatchNo)
	INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode AND ItemRateId=(SELECT MAX(ItemRateId) 
	FROM SCPStRate CPP WHERE SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode=SCPStItem_M.ItemCode)
	WHERE SCPStItem_M.IsActive=1 --AND SCPStItem_M.ItemName LIKE '%'+@ItemDesc+'%'
	GROUP BY SCPStItem_M.ItemCode,ItemName,DosageName,StrengthIdName,SCPTnStock_M.BatchNo,SCPStRate.CostPrice,SCPTnGoodReceiptNote_D.ItemRate,CurrentStock 
	ORDER BY SCPStItem_M.ItemCode


END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_C]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPrintSlipCount] 
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT CASE WHEN PatientTypeId IN (2,9) OR PatientSubCategoryId=2 THEN 1 ELSE 2 END AS PrintCount
    FROM SCPTnSale_M WHERE TRANS_ID=@TRNSCTN_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnSale_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetSale_D]
(
@DDLID varchar(50)
)
AS
BEGIN
--SELECT i.ItemCode,i.ItemName,S.SignaName,ST.CurrentStock,st.StockId,c.TradePrice,i.Pneumonics
--FROM SCPStItem_M i

--inner join SCPStSigna S on I.SignaId=S.SignaId 
--inner join SCPTnStock_D ST on st.ItemCode=i.ItemCode 
--AND isnull(ST.StockId,0)=(select  ISNULL(max(StockId),0) from SCPTnStock_D iv where i.ItemCode=iv.ItemCode)  
--inner join SCPStRate c on  c.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
--where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ITM_CODE=i.ItemCode)
--where i.ItemCode=@DDLID
--SELECT ItemCode,ItemName,Pneumonics,SignaName,CurrentStock,CASE WHEN TradePrice=0 
--THEN (SELECT SalePrice FROM SCPStRate WHERE ItemCode=TMPP.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate) END AS TradePrice,
--GenericName,CategoryName,SubCategoryName,UnitName,ShelfName,RouteOfAdministrationTitle,StrengthIdName FROM
--(
	SELECT ItemCode,ItemName,Pneumonics,SignaName,ISNULL(SUM(CurrentStock),0) AS CurrentStock,
	CASE WHEN ISNULL(SUM(CurrentStock),0)=0 THEN ISNULL((SELECT TOP 1 SalePrice FROM SCPTnGoodReceiptNote_D 
	WHERE SCPTnGoodReceiptNote_D.ItemCode=TMP.ItemCode ORDER BY TRNSCTN_ID DESC),0) ELSE MAX(SalePrice)
	END AS TradePrice,GenericName,CategoryName,SubCategoryName,UnitName,ShelfName,RouteOfAdministrationTitle,StrengthIdName FROM 
	(
	--SELECT i.ItemCode,i.ItemName,S.SignaName,STCK.CurrentStock,PRC.BatchNo,CASE WHEN CurrentStock=0 
	--THEN 0 ELSE SalePrice END AS SalePrice,i.Pneumonics,g.GenericName,ca.CategoryName,S_ca.SubCategoryName,
	--u.UnitName,isnull(sh.ShelfName,'') as ShelfName,roa.RouteOfAdministrationTitle,sth.StrengthIdName FROM SCPStItem_M i
	--inner join SCPStGeneric g on g.GenericId=i.GenericId
	--inner join SCPStCategory ca on ca.CategoryId=i.CategoryId
	--inner join SCPStSubCategory S_ca on S_ca.SubCategoryId=i.SubCategoryId
	--inner join SCPStMeasuringUnit u on u.UnitId=i.ItemUnit
	--Left Outer join SCPStItem_D_Shelf shelf on shelf.ItemCode=i.ItemCode and WraehouseId=3
	--Left Outer join SCPStShelf sh on sh.ShelfId=shelf.ShelfId
	--inner join SCPStRouteOfAdministration roa on roa.RouteOfAdministrationId=i.RouteOfAdministrationId
	--Left Outer join SCPStStrengthId sth on sth.StrengthIdId=i.StrengthId
	--inner join SCPStSigna S on I.SignaId=S.SignaId 
	--inner join SCPTnStock_M STCK ON STCK.ItemCode=i.ItemCode and STCK.WraehouseId=3
	--LEFT outer JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = I.ItemCode AND PRC.BatchNo=STCK.BatchNo 
		SELECT distinct i.ItemCode,i.ItemName,S.SignaName,STCK.CurrentStock,STCK.BatchNo,CASE WHEN STCK.CurrentStock=0 THEN 0 
		WHEN PRC.SalePrice IS NULL THEN PRIC.SalePrice ELSE PRC.SalePrice END AS SalePrice,i.Pneumonics,g.GenericName,
		ca.CategoryName,S_ca.SubCategoryName,u.UnitName,isnull(sh.ShelfName,'') as ShelfName,roa.RouteOfAdministrationTitle,sth.StrengthIdName FROM SCPStItem_M i
		inner join SCPStGeneric g on g.GenericId=i.GenericId
		inner join SCPStCategory ca on ca.CategoryId=i.CategoryId
		inner join SCPStSubCategory S_ca on S_ca.SubCategoryId=i.SubCategoryId
		inner join SCPStMeasuringUnit u on u.UnitId=i.ItemUnit
		Left Outer join SCPStItem_D_Shelf shelf on shelf.ItemCode=i.ItemCode and WraehouseId=3
		Left Outer join SCPStShelf sh on sh.ShelfId=shelf.ShelfId
		inner join SCPStRouteOfAdministration roa on roa.RouteOfAdministrationId=i.RouteOfAdministrationId
		Left Outer join SCPStStrengthId sth on sth.StrengthIdId=i.StrengthId
		inner join SCPStSigna S on I.SignaId=S.SignaId 
		inner join SCPTnStock_M STCK ON STCK.ItemCode=i.ItemCode and STCK.WraehouseId=3
		left JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = I.ItemCode AND PRC.BatchNo=STCK.BatchNo 
		AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
		WHERE SCPTnGoodReceiptNote_D.ItemCode = I.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = STCK.BatchNo ORDER BY CreatedDate DESC)
		left JOIN SCPStRate PRIC ON PRIC.ItemCode = I.ItemCode AND PRIC.FromDate <= STCK.CreatedDate and PRIC.ToDate >= STCK.CreatedDate
		where i.Pneumonics=@DDLID and i.IsActive=1
	)TMP
	GROUP BY ItemCode,ItemName,SignaName,Pneumonics,GenericName,CategoryName,SubCategoryName,UnitName,ShelfName,RouteOfAdministrationTitle,StrengthIdName
	--order by ItemName
--)TMPP
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnSale_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSale_M]
@SlipNo as varchar(50)
AS
BEGIN
	select Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM,
    isnull(PatientSubCategoryId,0) as PatientSubCategoryId, isnull(PatientTypeId,0) as PatientTypeId,isnull(CompanyId,0) as CompanyId,
    isnull(ConsultantId,0) as ConsultantId,isnull(CareOffCode,0) as CareOffCode,isnull(CareOff,0) as CareOff from SCPTnSale_M
	where TRANS_ID=@SlipNo
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnSale_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoSaleAmount]
	@BatchNo as varchar(50)
AS
BEGIN
	SELECT sum(SCPTnSale_D.Amount) as TotalSale FROM SCPTnSale_D 
    INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId 
    where SCPTnSale_M.BatchNo=@BatchNo
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnSale_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetKitItemsForSale]
(
@kit varchar(50)
)
AS
BEGIN
--select d.ItemCode,d.Quantity,i.Pneumonics,g.SignaName,s.GenericName,
--CASE WHEN MAX(PRC.SalePrice) IS NULL 
--THEN MAX(PRIC.SalePrice) ELSE MAX(PRC.SalePrice) END AS SalePrice,
--(d.Quantity*(CASE WHEN MAX(PRC.SalePrice) IS NULL 
--THEN MAX(PRIC.SalePrice) ELSE MAX(SalePrice) END)) as AMOUNT,
--i.ItemName,ISNULL(SUM(CurrentStock),0) as CurrentStock from SCPStKit_M m
--inner join SCPStKit_D d on d.PARENT_TRNSCTN_ID=m.KitId
--inner join SCPStItem_M i on i.ItemCode=d.ItemCode 
--inner join SCPStSigna g on g.SignaId=i.SignaId 
--inner join SCPStGeneric s on s.GenericId=i.GenericId 
--inner join SCPTnStock_M STCK ON STCK.ItemCode=i.ItemCode and STCK.WraehouseId=3
--left JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = I.ItemCode AND PRC.BatchNo=STCK.BatchNo 
--		AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D 
--		WHERE SCPTnPharmacyIssuance_D.ItemCode = I.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = STCK.BatchNo ORDER BY CreatedDate DESC)
--left JOIN SCPStRate PRIC ON PRIC.ItemCode = I.ItemCode AND PRIC.FromDate <= STCK.CreatedDate and PRIC.ToDate >= STCK.CreatedDate
--where m.KitId=@kit and i.IsActive=1 and d.IsActive=1 and m.IsActive=1
--group by d.ItemCode,d.Quantity,i.Pneumonics,g.SignaName,s.GenericName,i.ItemName

SELECT ItemCode,ItemName,Pneumonics,SignaName,Quantity,SalePrice,GenericName,CurrentStock,Quantity*SalePrice AMOUNT FROM
(
    SELECT ItemCode,ItemName,Pneumonics,SignaName,ISNULL(SUM(CurrentStock),0) AS CurrentStock,Quantity,
	CASE WHEN ISNULL(SUM(CurrentStock),0)=0 THEN ISNULL((SELECT TOP 1 SalePrice FROM SCPTnGoodReceiptNote_D 
	WHERE SCPTnGoodReceiptNote_D.ItemCode=TMP.ItemCode ORDER BY TRNSCTN_ID DESC),0) ELSE MAX(SalePrice)
	END AS SalePrice,GenericName FROM 
	(
		select distinct d.ItemCode,d.Quantity,i.Pneumonics,g.SignaName,s.GenericName,
		STCK.BatchNo,CASE WHEN STCK.CurrentStock=0 THEN 0 WHEN PRC.SalePrice IS NULL 
		THEN PRIC.SalePrice ELSE PRC.SalePrice END AS SalePrice,
		i.ItemName,STCK.CurrentStock from SCPStKit_M m
		inner join SCPStKit_D d on d.PARENT_TRNSCTN_ID=m.KitId
		inner join SCPStItem_M i on i.ItemCode=d.ItemCode 
		inner join SCPStSigna g on g.SignaId=i.SignaId 
		inner join SCPStGeneric s on s.GenericId=i.GenericId 
		inner join SCPTnStock_M STCK ON STCK.ItemCode=i.ItemCode and STCK.WraehouseId=3
		left JOIN SCPTnGoodReceiptNote_D PRC ON PRC.ItemCode = I.ItemCode AND PRC.BatchNo=STCK.BatchNo 
		AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
		WHERE SCPTnGoodReceiptNote_D.ItemCode = I.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = STCK.BatchNo ORDER BY CreatedDate DESC)
		left JOIN SCPStRate PRIC ON PRIC.ItemCode = I.ItemCode AND PRIC.FromDate <= STCK.CreatedDate and PRIC.ToDate >= STCK.CreatedDate
		where m.KitId=@kit and i.IsActive=1 and d.IsActive=1 and m.IsActive=1
	)TMP
	GROUP BY ItemCode,ItemName,SignaName,Pneumonics,GenericName,Quantity
)TMPP
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_G]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetInPatientData]
(
@IP VARCHAR(50)

)
AS
BEGIN

--select *
--from SCPTnInPatient p
--where PatientIp like '%'+ @IP + '%'


select ID,PatientIp,PatientTypeId,NamePrefix,FirstName,LastName,CareOffCode,
	CAST(isnull(CAST(CareOff AS bigint),0) AS VARCHAR(50)) as CareOff,CompanyId,PatientCategoryId,PatientWard,RoomNo,
	ConsultantId,Status,IsActive,CreatedBy,CreatedDate,EDTD_BY,EditedDate,RW_STMP from SCPTnInPatient p where PatientIp =@IP

--select *
--from SCPTnInPatient p
--where (PatientIp+'  ||  '+FirstName+' '+LastName) like '%'+ @IP + '%' 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGenerateSaleNo]
AS
BEGIN
SELECT RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+
RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+
RIGHT('0000'+CAST(COUNT(ID.TRANS_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnSale_M ID 
	WHERE MONTH(CreatedDate) = MONTH(getdate())
    AND YEAR(CreatedDate) = YEAR(getdate()) 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPSaleNoForSearch] 
@Search as varchar(50)
	
AS
BEGIN
     SELECT TRANS_ID AS TRANS_ID,TRANS_ID AS SINo,TRANS_DT 
	 FROM SCPTnSale_M WHERE IsActive=1 and PatientIp='0'
	 AND DATEDIFF(DAY,TRANS_DT,GETDATE())<=30 AND TRANS_ID like '%'+@Search+'%' 
	 order by TRANS_ID desc

	 --SELECT SUBSTRING(TRANS_ID, 4, 50) AS TRANS_ID,SUBSTRING(TRANS_ID, 4, 50) AS SINo 
	 --FROM SCPTnSale_M WHERE IsActive=1 and PatientIp='0'AND TRANS_ID like '%'+@Search+'%'
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientTypeList] 
AS
BEGIN
SELECT C.PatientTypeId,C.PatientTypeName
FROM SCPStPatientType C WHERE IsActive=1
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L10]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemsDetailByIpAndPaymentTerm]
@ParentID as varchar(50),
@PaymentTerm as INT
AS
BEGIN

  WITH CTE AS
   (
    SELECT SCPTnSale_D.ItemCode,SCPStItem_M.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D dd 
	WHERE dd.ItemCode=SCPTnSale_D.ItemCode and dd.PARNT_TRANS_ID=@ParentID AND dd.PaymentTermId=@PaymentTerm) AS BatchNo,
	Max(SCPTnSale_D.ItemRate) as PRICE,(sum(isnull(SCPTnSale_D.Quantity,0)) - (select isnull(SUM(ReturnQty),0) from SCPTnSaleRefund_D
	INNER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID and SCPTnSaleRefund_M.SaleRefundId=@ParentID 
	where ItemCode=SCPTnSale_D.ItemCode AND PaymentTermId=@PaymentTerm)) AS Quantity,
	SUM(ROUND(SCPTnSale_D.Quantity*SCPTnSale_D.ItemRate,0)) as Amount FROM SCPTnSale_D     
    LEFT OUTER JOIN SCPStItem_M ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
	where SCPTnSale_D.SaleId = @ParentID AND SCPTnSale_D.PaymentTermId=@PaymentTerm
	AND @ParentID NOT IN(SELECT TRANS_ID FROM SCPTnSale_M where PatientIp!='0')
	GROUP BY SCPTnSale_D.ItemCode,SCPStItem_M.ItemName,PaymentTermId
	)
  select ItemCode,ItemName,BatchNo,PRICE,Quantity,ROUND((PRICE*Quantity),0) AS Amount
  FROM CTE  where Quantity>0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L11]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemByIp]
@PatientId as varchar(50)
AS
BEGIN

 --WITH CTE AS
 --  (
	-- select ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
 --  from
 --  (
	--	SELECT SL_D.ItemCode,ITM.ItemName,isnull(SL_D.PaymentTermId,0) as PaymentTermId,(SELECT TOP 1 BatchNo FROM SCPTnSale_D WHERE 
	--	SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,Max(SL_D.ItemRate) as PRICE,
	--    (SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
	--	INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
	--	WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp ) AS SL_QTY, 
	--	(SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
	--	INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
	--	WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp )-SUM(iSNULL(RTN_D.ReturnQty,0)) as RemainingQty,
	--	SUM(iSNULL(RTN_D.ReturnQty,0)) AS ReturnQty,sum(SL_D.Amount) as Amount
	--	FROM SCPTnSale_D SL_D
	--	LEFT OUTER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
	--	LEFT OUTER JOIN SCPTnSaleRefund_D RTN_D ON RTN_D.ItemCode = SL_D.ItemCode
	--	WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M WHERE SL_M.PatientIp = @PatientIp)
	--	GROUP BY ITM.ItemName, SL_D.ItemCode,SL_D.PaymentTermId
	--	 ) 
	--	tmp GROUP BY ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
	--     ) 
	--   SELECT Distinct ItemCode,ItemName
	--   FROM CTE WHERE RemainingQty>0
	 WITH CTE AS
   (
   select ItemCode,ItemName,Quantity
   from
   (
    SELECT SCPTnSale_D.ItemCode,SCPStItem_M.ItemName,
	(sum(isnull(SCPTnSale_D.Quantity,0)) - (select isnull(SUM(ReturnQty),0) from SCPTnSaleRefund_D
	INNER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID and 
	SCPTnSaleRefund_M.PatinetIp=@PatientId where SCPTnSaleRefund_D.ItemCode=SCPTnSale_D.ItemCode)) AS Quantity,
	(select isnull(SUM(ReturnQty),0) from SCPTnSaleRefund_D
	INNER JOIN SCPTnSaleRefund_M ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID and 
	SCPTnSaleRefund_M.PatinetIp=@PatientId where SCPTnSaleRefund_D.ItemCode=SCPTnSale_D.ItemCode) AS ReturnQty FROM SCPTnSale_D     
    INNER JOIN SCPStItem_M ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode and SCPStItem_M.IsActive=1
    INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
	WHERE SCPTnSale_M.PatientIp=@PatientId
	GROUP BY SCPTnSale_D.ItemCode,SCPStItem_M.ItemName
	)tmp GROUP BY ItemCode,ItemName,Quantity
	     ) 
	   select ItemCode,ItemName
	   FROM CTE where Quantity>0
		 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L12]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPartnerList]
AS
BEGIN
SELECT PartnerId,PartnerName
FROM SCPStPartner
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L13]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetKitList]
@PatientCateId as int
AS
BEGIN
	 select KitId,KitName from SCPStKit_M
     inner join SCPStKitCategory on SCPStKitCategory.KitCategoryIdegoryId = SCPStKit_M.KitCategoryId
     where SCPStKit_M.IsActive=1 and SCPStKitCategory.PatientCategoryId=@PatientCateId
 END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L14]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPatientForSearch]
@Search as varchar(50)
AS
BEGIN
	SELECT DISTINCT (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  AS PatientIp,
	(PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  as PatientIpNO
	FROM  SCPTnInPatient 	WHERE PatientIp LIKE '%'+@Search+'%'  --SCPTnInPatient.Status=1

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L15]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleByIpAndSbCategory]
@PatientId as varchar(50),
@PatientSbCatId as int
AS
BEGIN

--WITH CTE AS
--   (
--	 select ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
--   from
--   (
--		SELECT SL_D.ItemCode,ITM.ItemName,isnull(SL_D.PaymentTermId,0) as PaymentTermId,(SELECT TOP 1 BatchNo FROM SCPTnSale_D WHERE 
--		SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,Max(SL_D.ItemRate) as PRICE,
--	    (SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
--		INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
--		WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp ) AS SL_QTY, 
--		(SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
--		INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
--		WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp )-SUM(iSNULL(RTN_D.ReturnQty,0)) as RemainingQty,
--		SUM(iSNULL(RTN_D.ReturnQty,0)) AS ReturnQty,sum(SL_D.Amount) as Amount
--		FROM SCPTnSale_D SL_D
--		LEFT OUTER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
--		LEFT OUTER JOIN SCPTnSaleRefund_D RTN_D ON RTN_D.ItemCode = SL_D.ItemCode
--		WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M WHERE SL_M.PatientIp = @PatientIp
--		and SL_M.PatientSubCategoryId=@SCPTnInPatientSbCatId)
--		GROUP BY ITM.ItemName, SL_D.ItemCode,SL_D.PaymentTermId
--		 ) 
--		tmp GROUP BY ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
--	     ) 
--	   SELECT ItemCode,ItemName
--	   FROM CTE WHERE RemainingQty>0 

	--WITH CTE AS
 --  (
	-- select ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
 --  from
 --  (
	--	SELECT SL_D.ItemCode,ITM.ItemName,isnull(SL_D.PaymentTermId,0) as PaymentTermId,(SELECT TOP 1 BatchNo FROM SCPTnSale_D WHERE 
	--	SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,Max(SL_D.ItemRate) as PRICE,
	--    (SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
	--	INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
	--	WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp  ) AS SL_QTY, 
	--	(SELECT SUM(_SL_D.Quantity) FROM SCPTnSale_D _SL_D 
	--	INNER JOIN SCPTnSale_M _SL_M ON _SL_M.TRANS_ID = _SL_D.PARNT_TRANS_ID
	--	WHERE _SL_D.ItemCode = SL_D.ItemCode AND _SL_M.PatientIp = @PatientIp )-(SELECT SUM(iSNULL(RTN_D.ReturnQty,0)) FROM SCPTnSaleRefund_D RTN_D WHERE RTN_D.ItemCode =SL_D.ItemCode) as RemainingQty,
	--	(SELECT SUM(iSNULL(RTN_D.ReturnQty,0)) FROM SCPTnSaleRefund_D RTN_D WHERE RTN_D.ItemCode =SL_D.ItemCode ) AS ReturnQty,sum(SL_D.Amount) as Amount
	--	FROM SCPTnSale_D SL_D
	--	LEFT OUTER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
	--	LEFT OUTER JOIN SCPTnSaleRefund_D RTN_D ON RTN_D.ItemCode = SL_D.ItemCode
	--	WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M WHERE SL_M.PatientIp = @PatientIp 
	--	and SL_M.PatientSubCategoryId= @SCPTnInPatientSbCatId)
	--	GROUP BY ITM.ItemName, SL_D.ItemCode,SL_D.PaymentTermId
	--	 ) 
	--	tmp GROUP BY ItemCode,ItemName,PaymentTermId,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
	--     ) 
	--   SELECT DISTINCT ItemCode,ItemName
	--   FROM CTE WHERE RemainingQty>0 	 

	WITH CTE AS
	(
		 select ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
		 from
		 (
			SELECT SL_D.ItemCode,ITM.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D 
			INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId AND SCPTnSale_M.PatientIp = @PatientId 
			WHERE SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,Max(SL_D.ItemRate) as PRICE,SUM(SL_D.Quantity) AS SL_QTY,
			(SUM(SL_D.Quantity)-ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D 
			INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND 
			_SR_M.PatinetIp = @PatientId AND RT_D.PaymentTermId=SL_D.PaymentTermId),0)) as RemainingQty,
			ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D	
			INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND
			_SR_M.PatinetIp = @PatientId AND RT_D.PaymentTermId=SL_D.PaymentTermId),0) AS ReturnQty,sum(SL_D.Amount) as Amount	
			FROM SCPTnSale_D SL_D	
			INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
			WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M 
			WHERE SL_M.PatientIp =@PatientId and SL_M.PatientSubCategoryId=@PatientSbCatId 
			and PatientTypeId=(SELECT PatientTypeId FROM SCPTnInPatient WHERE PatientIp=@PatientId)) 
			GROUP BY ITM.ItemName, SL_D.ItemCode,SL_D.PaymentTermId
			 ) 
			tmp GROUP BY ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
		  ) 
		SELECT DISTINCT ItemCode,ItemName
		FROM CTE WHERE RemainingQty>0 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L16]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetAllPatientList]
AS
BEGIN
SELECT Distinct (SCPTnInPatient.PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  AS PatientIp,
      (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  as PatientIpNO
FROM  SCPTnInPatient Inner Join SCPTnSale_M ON SCPTnSale_M.PatientIp=SCPTnInPatient.PatientIp 
--WHERE SCPTnInPatient.Status=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L17]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAdmitPatientList]
AS
BEGIN
	   SELECT DISTINCT (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  AS PatientIp,
       (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  as PatientIpNO
	   FROM SCPTnInPatient INNER JOIN SCPTnSale_M on SCPTnSale_M.PatientIp=SCPTnInPatient.PatientIp
       WHERE SCPTnInPatient.Status=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L18]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoCashSale]
@BatchNo AS VARCHAR(50)
AS
BEGIN
	
	SET NOCOUNT ON;

   --select SUM(ROUND(Quantity*ItemRate,0))-(select isnull(SUM(ROUND(ReturnQty*ItemRate,0)),0) from SCPTnSaleRefund_M 
   --inner join SCPTnSaleRefund_D on SCPTnSaleRefund_M.TRNSCTN_ID = SCPTnSaleRefund_D.PARENT_TRNSCTN_ID
   --where SCPTnSaleRefund_M.BatchNo = @BatchNo and PaymentTermId = '1' and SCPTnSaleRefund_M.IsActive=1) from SCPTnSale_M 
   --inner join SCPTnSale_D on SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
   --where BatchNo = @BatchNo and PaymentTermId = '1' and SCPTnSale_M.IsActive=1

         Declare @Sale MONEY , @Refund MONEY
   Set @Sale = (select SUM(ROUND(Quantity*ItemRate,0)) from SCPTnSale_M 
   inner join SCPTnSale_D on SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
   where BatchNo = @BatchNo and PaymentTermId = '1' and SCPTnSale_M.IsActive=1)

   Set @Refund = (select isnull(SUM(ROUND(ReturnQty*ItemRate,0)),0) from SCPTnSaleRefund_M 
   inner join SCPTnSaleRefund_D on SCPTnSaleRefund_M.TRNSCTN_ID = SCPTnSaleRefund_D.PARENT_TRNSCTN_ID
   where SCPTnSaleRefund_M.BatchNo = @BatchNo and PaymentTermId = '1' and SCPTnSaleRefund_M.IsActive=1)

   SELECT ISNULL(@Sale,0)-ISNULL(@Refund,0) 

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L19]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemsListByIpAndPaymentTerm]
@PatientId as varchar(50),
@PaymentTerm as int
AS
BEGIN
    WITH CTE AS
      (
        SELECT SL_D.ItemCode,ITM.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D 
		INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId AND SCPTnSale_M.PatientIp = @PatientId
		WHERE SCPTnSale_D.ItemCode=SL_D.ItemCode AND PaymentTermId=@PaymentTerm) AS BatchNo,Max(SL_D.ItemRate) as PRICE,SUM(SL_D.Quantity) AS SL_QTY,
		(SUM(SL_D.Quantity)-ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D 
		INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID 
		WHERE RT_D.ItemCode = SL_D.ItemCode AND _SR_M.PatinetIp = @PatientId
		and RT_D.PaymentTermId=@PaymentTerm),0)) as RemainingQty,ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D	
		INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND
		_SR_M.PatinetIp = @PatientId and RT_D.PaymentTermId=@PaymentTerm),0) AS ReturnQty,SUM(ROUND(SL_D.Quantity*SL_D.ItemRate,0)) as Amount FROM SCPTnSale_D SL_D	
		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
		INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = SL_D.PARNT_TRANS_ID 
		WHERE SCPTnSale_M.PatientIp =@PatientId AND SL_D.PaymentTermId=@PaymentTerm GROUP BY SL_D.ItemCode,ITM.ItemName
	  ) 
	   SELECT DISTINCT ItemCode,ItemName
	   FROM CTE WHERE RemainingQty>0 
END

GO
/O
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L20]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemByIpAndPaymentTerm]
@PatientIp as varchar(50),
@ItemId as varchar(50),
@PaymentTerm as int
AS
BEGIN
 WITH CTE AS
      (
        SELECT SL_D.ItemCode,ITM.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D 
		INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId AND SCPTnSale_M.PatientIp = @PatientIp
		WHERE SCPTnSale_D.ItemCode=SL_D.ItemCode AND PaymentTermId=@PaymentTerm) AS BatchNo,Max(SL_D.ItemRate) as PRICE,SUM(SL_D.Quantity) AS SL_QTY,
		(SUM(SL_D.Quantity)-ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D 
		INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID 
		WHERE RT_D.ItemCode = SL_D.ItemCode AND _SR_M.PatinetIp = @PatientIp
		and RT_D.PaymentTermId=@PaymentTerm),0)) as RemainingQty,ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D	
		INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND
		_SR_M.PatinetIp = @PatientIp and RT_D.PaymentTermId=@PaymentTerm),0) AS ReturnQty,SUM(ROUND(SL_D.Quantity*SL_D.ItemRate,0)) as Amount FROM SCPTnSale_D SL_D	
		INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
		INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = SL_D.PARNT_TRANS_ID 
		WHERE SCPTnSale_M.PatientIp =@PatientIp AND SL_D.PaymentTermId=@PaymentTerm GROUP BY SL_D.ItemCode,ITM.ItemName
	  ) 
	    SELECT ItemName,BatchNo,PRICE,RemainingQty as Quantity,ROUND((PRICE*RemainingQty),0) as Amount
	   FROM CTE where ItemCode=@ItemId and RemainingQty>0 order by ItemCode desc
	
END
GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetConsultantList]
AS
BEGIN
SELECT C.HIMSConsultantId AS  ConsultantId,C.ConsultantName
FROM SCPStConsultant C WHERE IsActive=1 order by C.ConsultantName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetLast15DaysInPatientForSearch]
@Search as varchar(50)
AS
BEGIN
    SELECT DISTINCT (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  AS PatientIp,
	(PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName)  as PatientIpNO FROM  SCPTnInPatient 
	WHERE DATEDIFF(DAY,EditedDate,GETDATE())<=15 AND  
	(PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName) LIKE '%'+@Search+'%'  --SCPTnInPatient.Status=1
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_L8]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetItemByPneumonicsForSearch]
(
@PNUMONCS VARCHAR(50)
)
AS
BEGIN
SELECT ItemCode,ItemName 
FROM SCPStItem_M  M
WHERE M.Pneumonics LIKE '%'+@PNUMONCS+ '%' AND IsActive=1
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPharmacySale]
@FromDate varchar(50),
@ToDate varchar(50),
@IP varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
		--IF (@ToDate !='0' AND  @FromDate!='0' AND @IP='0' )
		--		SELECT  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) AS DATE, PH_M.TRANS_ID, 
		--	CASE WHEN PH_M.PatientIp = '0' THEN NULL ELSE PH_M.PatientIp END AS PatientIp, PH_M.BatchNo,
		--	PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName AS SCPTnInPatientName, 
		--	PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, SUM(PH_D.Quantity) AS Quantity, ItemName
		--	FROM SCPTnSale_M PH_M
		--	INNER JOIN SCPTnSale_D PH_D ON PH_M.TRANS_ID = PH_D.PARNT_TRANS_ID
		--	INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
		--	INNER JOIN SCPStPatientType PT_TYP ON PH_M.PatientTypeId = PT_TYP.PatientTypeId 
		--	where  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) between @FromDate AND @ToDate 
		--	GROUP BY PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName,  PH_M.BatchNo,
		--	PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, ItemName,CONVERT(VARCHAR(50),PH_M.TRANS_DT,105),PH_M.TRANS_ID ,PH_M.PatientIp
		--	ORDER BY CONVERT(VARCHAR(50),PH_M.TRANS_DT,105)

		--ELSE IF (@ToDate !='0' AND @FromDate!='0' AND @IP != '0' )
		--	SELECT  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) AS DATE, PH_M.TRANS_ID, 
		--	CASE WHEN PH_M.PatientIp = '0' THEN NULL ELSE PH_M.PatientIp END AS PatientIp, PH_M.BatchNo,
		--	PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName AS SCPTnInPatientName, 
		--	PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, SUM(PH_D.Quantity) AS Quantity , ItemName
		--	FROM SCPTnSale_M PH_M
		--	INNER JOIN SCPTnSale_D PH_D ON PH_M.TRANS_ID = PH_D.PARNT_TRANS_ID
		--	INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
		--	INNER JOIN SCPStPatientType PT_TYP ON PH_M.PatientTypeId = PT_TYP.PatientTypeId 
		--	where  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) between @FromDate AND @ToDate 
		--	AND PH_M.PatientIp =@IP
		--	GROUP BY PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName,  PH_M.BatchNo,
		--	PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, ItemName,CONVERT(VARCHAR(50),PH_M.TRANS_DT,105),PH_M.TRANS_ID ,PH_M.PatientIp
		--	ORDER BY CONVERT(VARCHAR(50),PH_M.TRANS_DT,105)
				
				
				IF (@ToDate !='0' AND  @FromDate!='0' AND @IP='0' )
				SELECT  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) AS DATE, PH_M.TRANS_ID, 
			CASE WHEN PH_M.PatientIp = '0' THEN NULL ELSE PH_M.PatientIp END AS PatientIp, PH_M.BatchNo,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName AS SCPTnInPatientName, 
			PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, SUM(PH_D.Quantity) AS Quantity, ItemName
			FROM SCPTnSale_M PH_M
			INNER JOIN SCPTnSale_D PH_D ON PH_M.TRANS_ID = PH_D.PARNT_TRANS_ID
			INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
			INNER JOIN SCPStPatientType PT_TYP ON PH_M.PatientTypeId = PT_TYP.PatientTypeId 
			where  cast(PH_M.TRANS_DT as date) between cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(datetime,@Todate,103) as date)
		GROUP BY TRANS_DT, PH_M.TRANS_ID, PH_M.PatientIp, PH_M.BatchNo,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName, 
			PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount,  ItemName
			
			

		ELSE IF (@ToDate !='0' AND @FromDate!='0' AND @IP != '0' )
			SELECT  CONVERT(VARCHAR(50),PH_M.TRANS_DT,105) AS DATE, PH_M.TRANS_ID, 
			CASE WHEN PH_M.PatientIp = '0' THEN NULL ELSE PH_M.PatientIp END AS PatientIp, PH_M.BatchNo,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName AS SCPTnInPatientName, 
			PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount, SUM(PH_D.Quantity) AS Quantity , ItemName
			FROM SCPTnSale_M PH_M
			INNER JOIN SCPTnSale_D PH_D ON PH_M.TRANS_ID = PH_D.PARNT_TRANS_ID
			INNER JOIN SCPStItem_M ITM ON PH_D.ItemCode = ITM.ItemCode
			INNER JOIN SCPStPatientType PT_TYP ON PH_M.PatientTypeId = PT_TYP.PatientTypeId 
			where  cast(PH_M.TRANS_DT as date) between cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(datetime,@Todate,103) as date)
			AND PH_M.PatientIp =@IP
	GROUP BY TRANS_DT, PH_M.TRANS_ID, PH_M.PatientIp, PH_M.BatchNo,
			PT_TYP.PatientTypeName, PH_M.NamePrefix +' '+ PH_M.FirstName +' '+ PH_M.LastName, 
			PH_D.ItemCode, PH_D.ItemRate, PH_D.Amount,  ItemName
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacySaleForSearch]
@SEARCH as varchar(50)

AS
BEGIN
	SELECT CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,PatientIp,NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,
	TRANS_ID,UserName,BatchNo FROM SCPTnSale_M 
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnSale_M.CreatedBy
	WHERE (NamePrefix+' '+FirstName+' '+LastName) LIKE '%'+@SEARCH+'%' 
	OR SCPTnSale_M.BatchNo LIKE '%'+@SEARCH+'%' OR SCPTnSale_M.SaleId LIKE '%'+@SEARCH+'%' OR
	SCPTnSale_M.PatientIp LIKE '%'+@SEARCH+'%' OR CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) LIKE '%'+@SEARCH+'%' 
	OR UserName LIKE '%'+@SEARCH+'%' ORDER BY SCPTnSale_M.SaleId DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_S1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPharmacysale_D]
@PARENT_ID AS VARCHAR(50)
AS
BEGIN
	SELECT PARNT_TRANS_ID,SCPTnSale_D.ItemCode,Pneumonics,ItemName,SUM(STOCK) AS STOCK,
	DOSE,SignaId,PRICE,Duration,SUM(Quantity) AS Quantity,Amount FROM SCPTnSale_D
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnSale_D.ItemCode 
	WHERE PARNT_TRANS_ID=@PARENT_ID
	GROUP BY PARNT_TRANS_ID,SCPTnSale_D.ItemCode,Pneumonics,ItemName,DOSE,SignaId,PRICE,Duration,Amount
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM001_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPharmacysale_M]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	SELECT DISTINCT SCPTnSale_M.SaleId,TRANS_DT,PatientIp,PatientCategoryId,PatientSubCategoryId,PatientTypeId,
	SCPTnSale_M.FirstName,SCPTnSale_M.NamePrefix,SCPTnSale_M.LastName,CompanyId,ISNULL(RoomNo,'') AS RoomNo,SCPTnSale_M.ConsultantId,
	SCPTnSale_M.CareOff,SCPTnSale_M.CareOffCode,ISNULL(EmployeeName,'') AS EmployeeName,PaymentTermId,ReceivedAmount FROM SCPTnSale_M
	LEFT OUTER JOIN SCPTnInPatient ON SCPTnSale_M.PatientIp = SCPTnInPatient.PatientIp
	LEFT OUTER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode = SCPTnSale_M.CareOff
	INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId WHERE SCPTnSale_M.SaleId=@TRNSCTN_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSalePatientLast15DaysForSearch]
@SCPTnInPatientSearch as varchar(50)
AS
BEGIN
	select (PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName) AS PatientIp,
	(PatientIp+'  ||  '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName) as SCPTnInPatient_NM from SCPTnInPatient 
	where PatientIp IN (SELECT DISTINCT PatientIp FROM SCPTnSale_M) AND DATEDIFF(DAY,EditedDate,GETDATE())<=15 
	AND	(PatientIp like '%'+@SCPTnInPatientSearch+'%')
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemsByIpAndSbCategory]
@PatientIp as varchar(50),
@ItemId as varchar(50),
@PatientSbCatId as int
AS
BEGIN

 --  WITH CTE AS
 --  (
	-- select ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
 --    from
 --    (
	--    SELECT SL_D.ItemCode,ITM.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D 
	--	INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId AND 
	--	SCPTnSale_M.PatientIp = @PatientIp WHERE SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,
	--	Max(SL_D.ItemRate) as PRICE,SUM(SL_D.Quantity) AS SL_QTY,(SUM(SL_D.Quantity)-ISNULL((SELECT 
	--	SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID 
	--	WHERE RT_D.ItemCode = SL_D.ItemCode AND _SR_M.PatinetIp = @PatientIp	and RT_D.PaymentTermId=case when 
	--	@SCPTnInPatientSbCatId=1 then 2 else 1 end),0)) as RemainingQty,	ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D	
	--	INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND
	--	_SR_M.PatinetIp = @PatientIp and RT_D.PaymentTermId=case when @SCPTnInPatientSbCatId=1 then 2 else 1 end),0) AS ReturnQty,
	--	SUM(ROUND(SL_D.Quantity*SL_D.ItemRate,0)) as Amount	FROM SCPTnSale_D SL_D	INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode and ITM.IsActive=1
	--	WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M WHERE SL_M.PatientIp =@PatientIp
	--	and SL_M.PatientSubCategoryId=@SCPTnInPatientSbCatId) GROUP BY ITM.ItemName, SL_D.ItemCode

	--	 ) 
	--	tmp GROUP BY ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
	--    ) 
	--SELECT ItemName,BatchNo,PRICE,RemainingQty as Quantity,(PRICE*RemainingQty) as Amount
	--FROM CTE where ItemCode=@ItemId and RemainingQty>0 order by ItemCode desc


	  WITH CTE AS
	 (
	   select ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
       from
       (
	    SELECT SL_D.ItemCode,ITM.ItemName,(SELECT TOP 1 BatchNo FROM SCPTnSale_D 
			INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId AND SCPTnSale_M.PatientIp = @PatientIp 
			WHERE SCPTnSale_D.ItemCode=SL_D.ItemCode) AS BatchNo,Max(SL_D.ItemRate) as PRICE,SUM(SL_D.Quantity) AS SL_QTY,
			(SUM(SL_D.Quantity)-ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D 
			INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND 
			_SR_M.PatinetIp = @PatientIp AND RT_D.PaymentTermId=SL_D.PaymentTermId),0)) as RemainingQty,
			ISNULL((SELECT SUM(RT_D.ReturnQty) FROM SCPTnSaleRefund_D RT_D	
			INNER JOIN SCPTnSaleRefund_M _SR_M ON _SR_M.TRNSCTN_ID = RT_D.PARENT_TRNSCTN_ID WHERE RT_D.ItemCode = SL_D.ItemCode AND
			_SR_M.PatinetIp = @PatientIp AND RT_D.PaymentTermId=SL_D.PaymentTermId),0) AS ReturnQty,
			SUM(ROUND(SL_D.Quantity*SL_D.ItemRate,0)) as Amount	FROM SCPTnSale_D SL_D	
			INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SL_D.ItemCode
			WHERE SL_D.PARNT_TRANS_ID IN (SELECT SL_M.TRANS_ID FROM SCPTnSale_M SL_M 
			WHERE SL_M.PatientIp =@PatientIp and SL_M.PatientSubCategoryId=@PatientSbCatId 
			and PatientTypeId=(SELECT PatientTypeId FROM SCPTnInPatient WHERE PatientIp=@PatientIp)) 
			GROUP BY ITM.ItemName, SL_D.ItemCode,SL_D.PaymentTermId
		 ) 
		tmp GROUP BY ItemCode,ItemName,BatchNo,PRICE,SL_QTY,ReturnQty,RemainingQty,Amount
	   ) 
	   SELECT ItemName,BatchNo,PRICE,RemainingQty as Quantity,(PRICE*RemainingQty) as Amount
	   FROM CTE where ItemCode=@ItemId and RemainingQty>0 order by ItemCode desc
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleItemDetailBySaleNo]
@SaleInvNo as varchar(50),
@ItemId as varchar(50)
AS
BEGIN
	SELECT SCPTnSale_D.PaymentTermId,(SELECT TOP 1 BatchNo FROM SCPTnSale_D WHERE SCPTnSale_D.ItemCode=@ItemId) AS BatchNo,
    SCPStItem_M.ItemName,Max(SCPTnSale_D.ItemRate) as PRICE,sum(SCPTnSale_D.Quantity) as Quantity,
	SUM(ROUND(SCPTnSale_D.Quantity*SCPTnSale_D.ItemRate,0)) as Amount FROM SCPTnSale_D 
	INNER JOIN SCPStItem_M ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode 
	INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = SCPTnSale_D.SaleId
	where SCPTnSale_M.SaleId=@SaleInvNo and SCPTnSale_D.ItemCode=@ItemId and SCPStItem_M.IsActive=1
	group by SCPStItem_M.ItemCode,SCPStItem_M.ItemName,SCPTnSale_D.PaymentTermId,SCPTnSale_D.ItemRate
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPatientDataForRefund]
@patId as varchar(50)
AS
BEGIN
	--select PatientIp,Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM,PatientCategoryId,PatientTypeId from SCPTnInPatient
    --   where  PatientIp=@patId
	--select Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM,isnull(PatientCategoryId,0) as PatientCategoryId,
 --   isnull(PatientSubCategoryId,0) as PatientSubCategoryId, isnull(PatientTypeId,0) as PatientTypeId,isnull(CompanyId,0) as CompanyId,
 --   isnull(ConsultantId,0) as ConsultantId,isnull(CareOffCode,0) as CareOffCode,isnull(CareOff,0) as CareOff from SCPTnSale_M
	--where PatientIp=@patId

	select Cast(NamePrefix+' '+FirstName+' '+LastName as varchar) as PATNT_NM, PatientCategoryId as PatientCategoryId,
    isnull(PatientWard,0) as PatientSubCategoryId, isnull(PatientTypeId,0) as PatientTypeId,isnull(CompanyId,0) as CompanyId,
    isnull(ConsultantId,0) as ConsultantId,isnull(CareOffCode,0) as CareOffCode,
	CAST(isnull(CAST(CareOff AS bigint),0) AS VARCHAR(50)) as CareOff from SCPTnInPatient
	where PatientIp=@patId

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateSaleRefundNo]

AS
BEGIN
	SELECT RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnSaleRefund_M
	WHERE MONTH(CreatedDate) = MONTH(getdate())
    AND YEAR(CreatedDate) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAdmitPatientForRefund]
AS
BEGIN
	 SELECT distinct SCPTnSale_M.PatientIp as PatientIp, SCPTnSale_M.PatientIp as PatientIpNO  FROM  SCPTnInPatient 
	 INNER JOIN SCPTnSale_M ON SCPTnInPatient.PatientIp = SCPTnSale_M.PatientIp WHERE SCPTnInPatient.Status=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSaleRefundByRefundNo_M]
 
@TransactionId as varchar(50)
AS
BEGIN
      select * from SCPTnSaleRefund_M where TRNSCTN_ID=@TransactionId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleRefundForSearch]
@SEARCH as varchar(50)

AS
BEGIN
	  SELECT TRANS_DT,PatientIp,SCPTnInPatient_NM,TRNSCTN_ID,UserName,BatchNo FROM
   (
    SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSaleRefund_M.TRNSCTN_DATE, 105) AS TRANS_DT,PatientIp,NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,
	TRNSCTN_ID,UserName,SCPTnSaleRefund_M.BatchNo FROM SCPTnSaleRefund_M 
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnSaleRefund_M.CreatedBy
	INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId = SCPTnSaleRefund_M.SaleRefundId AND SCPTnSaleRefund_M.PatinetIp='0'
	WHERE (NamePrefix+' '+FirstName+' '+LastName) LIKE '%'+@SEARCH+'%' 
	OR SCPTnSaleRefund_M.BatchNo LIKE '%'+@SEARCH+'%' OR SCPTnSaleRefund_M.TRNSCTN_ID LIKE '%'+@SEARCH+'%' OR
	SCPTnSaleRefund_M.PatinetIp LIKE '%'+@SEARCH+'%' OR CONVERT(VARCHAR(10), SCPTnSaleRefund_M.TRNSCTN_DATE, 105) LIKE '%'+@SEARCH+'%' 
	OR UserName LIKE '%'+@SEARCH+'%' 
	UNION ALL
	SELECT DISTINCT CONVERT(VARCHAR(10), SCPTnSaleRefund_M.TRNSCTN_DATE, 105) AS TRANS_DT,PatientIp,
	SCPTnInPatient.NamePrefix+' '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName AS SCPTnInPatient_NM,
	TRNSCTN_ID,UserName,SCPTnSaleRefund_M.BatchNo FROM SCPTnSaleRefund_M 
	INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnSaleRefund_M.CreatedBy
	INNER JOIN SCPTnSale_M ON SCPTnSale_M.PatientIp = SCPTnSaleRefund_M.PatinetIp AND SCPTnSale_M.PatientIp!='0'
	INNER JOIN SCPTnInPatient ON SCPTnSaleRefund_M.PatinetIp = SCPTnInPatient.PatientIp
	WHERE (SCPTnInPatient.NamePrefix+' '+SCPTnInPatient.FirstName+' '+SCPTnInPatient.LastName) LIKE '%'+@SEARCH+'%' 
	OR SCPTnSaleRefund_M.BatchNo LIKE '%'+@SEARCH+'%' OR SCPTnSaleRefund_M.TRNSCTN_ID LIKE '%'+@SEARCH+'%' OR
	SCPTnSaleRefund_M.PatinetIp LIKE '%'+@SEARCH+'%' OR CONVERT(VARCHAR(10), SCPTnSaleRefund_M.TRNSCTN_DATE, 105) LIKE '%'+@SEARCH+'%' 
	OR UserName LIKE '%'+@SEARCH+'%' 
	)TMP ORDER BY TRNSCTN_ID DESC
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_S1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleRefundByIp_D]
@PARENT_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnSaleRefund_D.ItemCode,ItemName,ItemRate,
	SCPTnSaleRefund_D.ItemPackingQuantity,SaleAmount,ReturnQty,ReturnAmount FROM SCPTnSaleRefund_D
	INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnSaleRefund_D.ItemCode 
	WHERE PARENT_TRNSCTN_ID=@PARENT_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM002_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetSaleRefundByRefundNo_D]
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	DECLARE @IP_NO AS VARCHAR(50)
	SET @IP_NO = (SELECT PatinetIp FROM SCPTnSaleRefund_M WHERE TRNSCTN_ID=@TRNSCTN_ID)
	IF (@IP_NO='0')
	 BEGIN
	  SELECT DISTINCT SCPTnSaleRefund_M.TRNSCTN_ID,SCPTnSaleRefund_M.TRNSCTN_DATE,SCPTnSaleRefund_M.PatinetIp,PatientCategoryId,PatientSubCategoryId,
	  PatientTypeId,	(NamePrefix+' '+FirstName+' '+LastName) AS SCPTnInPatient_NM,CompanyId,'0' AS RoomNo,
	  ConsultantId,CAST(isnull(CAST(CareOff AS bigint),0) AS VARCHAR(50)) CareOff,CareOffCode,
	  ISNULL(EmployeeName,'') AS EmployeeName,SCPTnSaleRefund_D.PaymentTermId FROM SCPTnSaleRefund_M
	  LEFT OUTER JOIN SCPTnSale_M ON SCPTnSaleRefund_M.SaleRefundId = SCPTnSale_M.SaleId
	  LEFT OUTER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode = SCPTnSale_M.CareOff
	  INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID WHERE SCPTnSaleRefund_M.TRNSCTN_ID=@TRNSCTN_ID
	 END
	ELSE
	 BEGIN
	  SELECT DISTINCT SCPTnSaleRefund_M.TRNSCTN_ID,SCPTnSaleRefund_M.TRNSCTN_DATE,SCPTnSaleRefund_M.PatinetIp,CAST(PatientCategoryId AS bigint) 
	  AS PatientCategoryId, CAST(CASE WHEN SCPTnSaleRefund_D.PaymentTermId=2 AND SCPTnInPatient.PatientTypeId=1 THEN 2 ELSE 1 END AS bigint) AS PatientSubCategoryId,
	  CAST(PatientTypeId AS bigint) AS PatientTypeId, (NamePrefix+' '+FirstName+' '+LastName) AS SCPTnInPatient_NM,
	  CAST(CompanyId AS bigint) AS CompanyId,ISNULL(RoomNo,'') AS RoomNo,ConsultantId,
	  CAST(isnull(CAST(CareOff AS bigint),0) AS VARCHAR(50)) CareOff,
	  CareOffCode,ISNULL(EmployeeName,'') AS EmployeeName,SCPTnSaleRefund_D.PaymentTermId FROM SCPTnSaleRefund_M
	  LEFT OUTER JOIN SCPTnInPatient ON SCPTnSaleRefund_M.PatinetIp = SCPTnInPatient.PatientIp
	  LEFT OUTER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode = SCPTnInPatient.CareOff
	  INNER JOIN SCPTnSaleRefund_D ON SCPTnSaleRefund_D.PARENT_TRNSCTN_ID = SCPTnSaleRefund_M.TRNSCTN_ID WHERE SCPTnSaleRefund_M.TRNSCTN_ID=@TRNSCTN_ID
	 END
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemand_M] 
@trnsctnId as varchar(50)

AS
BEGIN
	
  SELECT TRNSCTN_DATE,WraehouseId FROM SCPTnDemand_M where TRNSCTN_ID=@trnsctnId 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemand_D]
@ParentTrnsctnId as varchar(50)

AS
BEGIN
  SELECT SCPTnDemand_D.TRNSCTN_ID,SCPTnDemand_D.ItemCode,SCPStItem_M.ItemName,isnull(SCPStItem_M.ItemPackingQuantity,0) as ItemPackingQuantity,SCPTnDemand_D.ItemBalance,SCPTnDemand_D.MinLevel,
  SCPTnDemand_D.MaxLevel,SCPTnDemand_D.DemandQty,SCPTnDemand_D.ReasonId,
  isnull((select IssueQty from SCPTnPharmacyIssuance_D where ItemCode=SCPTnDemand_D.ItemCode and DemandId=SCPTnDemand_D.PARENT_TRNSCTN_ID),0) as RcvdQty FROM SCPTnDemand_D
  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnDemand_D.ItemCode INNER JOIN SCPTnDemand_M ON SCPTnDemand_M.TRNSCTN_ID = SCPTnDemand_D.PARENT_TRNSCTN_ID 

   where SCPTnDemand_D.PARENT_TRNSCTN_ID=@ParentTrnsctnId and SCPStItem_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateDemandNo]

AS
BEGIN
	SELECT 'ID-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnDemand_M 
	WHERE MONTH(TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(TRNSCTN_DATE) = YEAR(getdate())

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandListPendingByWraehouseName] 
@WraehouseId as int
AS
BEGIN

 --   select Distinct SCPTnDemand_M.TRNSCTN_ID,
 --   SCPTnDemand_M.TRNSCTN_ID+'  '+CONVERT(VARCHAR(10), SCPTnDemand_M.TRNSCTN_DATE, 105)+'  '+ CONVERT(VARCHAR(5),SCPTnDemand_M.CreatedDate,108) as DemandNo 
 --   FROM SCPTnDemand_M
 --   INNER JOIN SCPTnDemand_D ON SCPTnDemand_D.PARENT_TRNSCTN_ID=SCPTnDemand_M.TRNSCTN_ID WHERE SCPTnDemand_M.IsActive=1 
	--AND SCPTnDemand_M.WraehouseId=@WraehouseId AND (SELECT COUNT(SCPTnDemand_D.ItemCode)
	--FROM SCPTnDemand_D WHERE SCPTnDemand_D.PARENT_TRNSCTN_ID=SCPTnDemand_M.TRNSCTN_ID AND SCPTnDemand_D.PendingQty>0)>0
	--	ORDER BY     SCPTnDemand_M.TRNSCTN_ID+'  '+CONVERT(VARCHAR(10), SCPTnDemand_M.TRNSCTN_DATE, 105)
	--+'  '+ CONVERT(VARCHAR(5),SCPTnDemand_M.CreatedDate,108) DESC
	SELECT * FROM
	(
	select Distinct SCPTnDemand_M.TRNSCTN_ID,
    SCPTnDemand_M.TRNSCTN_ID+'  '+CONVERT(VARCHAR(10), SCPTnDemand_M.TRNSCTN_DATE, 105)+'  '+ CONVERT(VARCHAR(5),SCPTnDemand_M.CreatedDate,108) as DemandNo 
    FROM SCPTnDemand_M
    INNER JOIN SCPTnDemand_D ON SCPTnDemand_D.PARENT_TRNSCTN_ID=SCPTnDemand_M.TRNSCTN_ID
	INNER JOIN SCPStItem_M ON SCPTnDemand_D.ItemCode = SCPStItem_M.ItemCode 
	WHERE SCPTnDemand_M.IsActive=1 AND SCPStItem_M.IsActive=1 AND SCPTnDemand_M.WraehouseId=@WraehouseId AND SCPTnDemand_D.PendingQty>0
	AND SCPTnDemand_M.DemandType='M'
	UNION ALL
	SELECT DISTINCT PARENT AS TRNSCTN_ID,
    PARENT+'  '+CONVERT(VARCHAR(10), TRNSCTN_DATE, 105)+'  '+ CONVERT(VARCHAR(5),MSTR_CreatedDate,108) as DemandNo FROM 
	( 
	SELECT TOP 1 SCPTnDemand_M.TRNSCTN_ID AS PARENT,TRNSCTN_DATE,SCPTnDemand_M.CreatedDate AS MSTR_CreatedDate FROM SCPTnDemand_M 
	WHERE SCPTnDemand_M.WraehouseId=@WraehouseId AND SCPTnDemand_M.DemandType='A' AND SCPTnDemand_M.IsActive=1 ORDER BY CreatedDate DESC
	)TMP 
	INNER JOIN SCPTnDemand_D ON SCPTnDemand_D.PARENT_TRNSCTN_ID=TMP.PARENT
	INNER JOIN SCPStItem_M ON SCPTnDemand_D.ItemCode = SCPStItem_M.ItemCode 
	WHERE  SCPStItem_M.IsActive=1 AND SCPTnDemand_D.PendingQty>0
	)TMPP ORDER BY TRNSCTN_ID DESC

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandPendingItems] 
@DemandNo as varchar(50)
AS
BEGIN
	 select SCPTnDemand_D.ItemCode,ITM.ItemName FROM SCPTnDemand_D INNER JOIN SCPStItem_M ITM ON SCPTnDemand_D.ItemCode = ITM.ItemCode 
	 where SCPTnDemand_D.PARENT_TRNSCTN_ID=@DemandNo and ITM.IsActive=1
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM003_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandForSearch] 
@Search as varchar(50),
@DmndType as varchar(1)
AS
BEGIN
	SELECT SCPTnDemand_M.TRNSCTN_ID, SCPTnDemand_M.TRNSCTN_DATE, SCPStWraehouse.WraehouseName
	FROM  SCPTnDemand_M INNER JOIN SCPStWraehouse ON SCPTnDemand_M.WraehouseId = SCPStWraehouse.WraehouseId
	where SCPTnDemand_M.DemandType=@DmndType and 
	SCPTnDemand_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY SCPTnDemand_M.TRNSCTN_ID desc
	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_B]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateBatchNo]

AS
BEGIN
	SELECT 'BN-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(BatchNo)+1 AS VARCHAR(50)),4) AS BatchNo
    FROM SCPTnBatchNo_M
	WHERE MONTH(BatchStartTime) = MONTH(getdate())
    AND YEAR(BatchStartTime) = YEAR(getdate())

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserBatchNoDetail]
@userId as int	
AS
BEGIN
	select BatchNo,BatchStartTime,OpeningClose,TerminalName from SCPTnBatchNo_M where UserId=@userId and IsActive=1 and BatchCloseTime is NULL
END

GO


/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserBatchNo]
@userId as int	
AS
BEGIN
	select isnull(BatchNo,'') from SCPTnBatchNo_M where UserId=@userId and IsActive=1 and BatchCloseTime is NULL
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoUserName]
@BatchNo as varchar(50),
@UsrId as int 
AS
BEGIN
	
	SET NOCOUNT ON;
	SELECT UserName FROM SCPTnBatchNo_M INNER JOIN SCPStUser_M ON SCPStUser_M.UserId = SCPTnBatchNo_M.CreatedBy 
	--INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.UserId = SCPTnBatchNo_D.UserId
 WHERE SCPTnBatchNo_M.BatchNo = @BatchNo AND SCPTnBatchNo_M.CreatedBy != @UsrId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_D5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoOpenCloseBalance]
@BatchNo as varchar(50),
@UsrId as int 
AS
BEGIN

	SET NOCOUNT ON;
    	SELECT (SELECT TOP (1) OpeningClose FROM SCPTnBatchNo_D WHERE UserId =@UsrId
	 AND BatchNo = @BatchNo order by ID DESC ) AS OPENING_BAL,(SELECT ISNULL(sum(SCPTnSale_D.Amount),0) as TotalSale FROM SCPTnSale_D 
    INNER JOIN SCPTnSale_M ON SCPTnSale_D.SaleId = SCPTnSale_M.SaleId 
    where SCPTnSale_M.BatchNo= @BatchNo and SCPTnSale_M.CreatedBy = @UsrId) AS SALE
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnBatchNo_M_D7]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetBatchNoUserId]
@BatchNo as varchar(50)
AS
BEGIN

	SET NOCOUNT ON;

  select CreatedBy from SCPTnBatchNo_M where BatchNo = @BatchNo
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandItemsForIssuance]
@WraehouseId as int,
@DemandId as varchar(50)
AS
BEGIN
	SELECT ItemCode,ItemName,DemandQty,BALANCE,IssueQty FROM
  (
    SELECT ItemCode,ItemName,DemandQty,BALANCE,CAST(CASE WHEN DemandQty<BALANCE THEN
     DemandQty ELSE BALANCE  END  AS decimal) AS IssueQty FROM 
      (
        SELECT ITM.ItemCode,ITM.ItemName,Dmnd.PendingQty as DemandQty, isnull((select sum(c.CurrentStock) from SCPTnStock_M as c
        where ItemCode=ITM.ItemCode and WraehouseId=@WraehouseId),0) AS BALANCE FROM SCPTnDemand_D Dmnd 
	    INNER JOIN SCPStItem_M ITM ON Dmnd.ItemCode = ITM.ItemCode and ITM.IsActive=1
	    WHERE 
		Dmnd.PARENT_TRNSCTN_ID = @DemandId and 
	    Dmnd.ItemCode not IN (SELECT distinct b.ItemCode FROM SCPTnPharmacyIssuance_D as b where Dmnd.PARENT_TRNSCTN_ID=b.DemandId)
	   )TMP
	)TMP WHERE IssueQty>0  AND BALANCE >= IssueQty
 --SELECT ItemCode,ItemName,DemandQty,BALANCE,IssueQty FROM
 -- (
 --    SELECT ItemCode,ItemName,DemandQty,BALANCE,CASE WHEN DemandQty<BALANCE 
 --    THEN (CEILING(CAST(DemandQty AS decimal)/CAST(ItemPackingQuantity  AS decimal)))*ItemPackingQuantity 
 --    WHEN ItemPackingQuantity=0 THEN 0 ELSE (BALANCE/ItemPackingQuantity)*ItemPackingQuantity  END AS IssueQty FROM 
 --     (
 --       SELECT ITM.ItemCode,ITM.ItemName,Dmnd.PendingQty as DemandQty, isnull((select sum(c.CurrentStock) from SCPTnStock_M as c
 --       where ItemCode=ITM.ItemCode and WraehouseId=@WraehouseId),0) AS BALANCE,ISNULL(ITM.ItemPackingQuantity,0) AS ItemPackingQuantity FROM SCPTnDemand_D Dmnd 
	--    INNER JOIN SCPStItem_M ITM ON Dmnd.ItemCode = ITM.ItemCode 
	--    WHERE Dmnd.PARENT_TRNSCTN_ID = @DemandId and 
	--    Dmnd.ItemCode not IN (SELECT distinct b.ItemCode FROM SCPTnPharmacyIssuance_D as b where Dmnd.PARENT_TRNSCTN_ID=b.DemandId)
	--   )TMP
	--)TMP WHERE IssueQty>0  AND BALANCE >= IssueQty

	--SELECT ITM.ItemCode,ITM.ItemName,Dmnd.PendingQty as DemandQty, isnull((select sum(c.CurrentStock) as ItemBalance from SCPTnStock_M as c
    --where ItemCode=ITM.ItemCode and WraehouseId=@WraehouseId),0) AS BALANCE 
	--FROM SCPTnDemand_D Dmnd INNER JOIN SCPStItem_M ITM ON Dmnd.ItemCode = ITM.ItemCode WHERE Dmnd.PARENT_TRNSCTN_ID = @DemandId
	--and Dmnd.ItemCode not IN (SELECT distinct b.ItemCode FROM SCPTnPharmacyIssuance_D as b where Dmnd.PARENT_TRNSCTN_ID=b.DemandId)

    --GROUP BY ITM.ItemCode,ITM.ItemName,Dmnd.DemandQty
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacyIssuance_M] 
@trnsctnId as varchar(50)

AS
BEGIN
	
  SELECT TRNSCTN_DATE,FromWarehouseId,ToWarehouseId FROM SCPTnPharmacyIssuance_M where TRNSCTN_ID=@trnsctnId 
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacyIssuance_D]
@ParentId as varchar(50)
AS
BEGIN
	  select DemandId,SCPTnPharmacyIssuance_D.ItemCode,ItemName,ItemBalance,DemandQty,IssueQty from SCPTnPharmacyIssuance_D
	  INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPTnPharmacyIssuance_D.ItemCode where PARENT_TRNSCTN_ID=@ParentId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePharmacyIssuanceNo]
AS
BEGIN
	SELECT 'PI-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnPharmacyIssuance_M 
	WHERE MONTH(TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(TRNSCTN_DATE) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacyIssuanceListByWareouse] 
@WraehouseId as int,
@ToWraehouseName as int
AS
BEGIN
   select TRNSCTN_ID,TRNSCTN_ID as IssuenceNo from SCPTnPharmacyIssuance_M where 
   TRNSCTN_ID NOT IN(select Distinct PharmacyIssuanceId from SCPTnPharmacyReceiving_M) AND
   FromWarehouseId=@WraehouseId and ToWarehouseId=@ToWraehouseName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM005_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPharmacyIssuanceForSearch]
@Search as varchar(50)
AS
BEGIN
	select TRNSCTN_ID,SCPStWraehouse.WraehouseName as FromWarehouseId ,(select WraehouseName from SCPStWraehouse where WraehouseId=SCPTnPharmacyIssuance_M.ToWarehouseId) as ToWarehouseId,
	TRNSCTN_DATE from SCPTnPharmacyIssuance_M INNER JOIN SCPStWraehouse ON SCPTnPharmacyIssuance_M.FromWarehouseId = SCPStWraehouse.WraehouseId
	where SCPTnPharmacyIssuance_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY TRNSCTN_ID DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM006_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE proc [dbo].[Sp_SCPGetReturnToStore]
(
@ParentId varchar(50))
AS
BEGIN
select b.TRNSCTN_ID,b.TRNSCTN_DATE,a.BatchNo,a.ItemBalance,a.ReturnQty,a.ItemCode,c.ItemName,SCPStReasonId.ReasonId as ReturnReasonIdId
from SCPTnReturnToStore_D as a 
inner join SCPTnReturnToStore_M as b on b.TRNSCTN_ID=a.PARENT_TRNSCTN_ID
inner join SCPStItem_M as c on c.ItemCode=a.ItemCode and c.IsActive=1
inner join SCPStReasonId on SCPStReasonId.ReasonId=a.ReturnReasonIdId
where b.TRNSCTN_ID=@ParentId
ORDER BY B.TRNSCTN_DATE DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM006_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGenerateReturnToStoreNo]

AS
BEGIN
	SELECT 'RP-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnReturnToStore_M

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM006_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToStoreListByWraehouseName]
@ToWarehouseId AS INT,
@FromWarehouseId AS INT
AS
BEGIN
	 SELECT TRNSCTN_ID,TRNSCTN_ID AS RTN_ID FROM SCPTnReturnToStore_M
     WHERE IsActive=1 AND ToWarehouseId=10 AND FromWarehouseId=3
     AND IsApprove=0
END


GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM006_S2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReturnToStoreForSearch]
@Trnsctn_ID as varchar(50)
AS
BEGIN
SELECT a.TRNSCTN_ID, a.TRNSCTN_DATE,b.WraehouseName
FROM  SCPTnReturnToStore_M as a inner join SCPStWraehouse as b on a.FromWarehouseId=b.WraehouseId
 where a.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' or a.TRNSCTN_DATE  like '%'+@Trnsctn_ID+'%' or b.WraehouseName like '%'+@Trnsctn_ID+'%'
 order by a.TRNSCTN_DATE desc
END













GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM007_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandItemForDiscard] 
@DemandId AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnDemand_D.ItemCode,SCPStItem_M.ItemName FROM SCPTnDemand_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnDemand_D.ItemCode and SCPStItem_M.IsActive=1 
    WHERE SCPTnDemand_D.PendingQty>0 AND SCPTnDemand_D.PARENT_TRNSCTN_ID=@DemandId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM007_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandItemDetailForDiscard]
@DMND_N0 AS VARCHAR(50),
@ITEM_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnDemand_D.DemandQty,SCPTnDemand_D.PendingQty,SCPTnDemand_D.DiscardQty FROM SCPTnDemand_D
    WHERE SCPTnDemand_D.PARENT_TRNSCTN_ID=@DMND_N0 AND SCPTnDemand_D.ItemCode=@ITEM_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM007_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateDemandDiscradNo]
AS
BEGIN
	SELECT 'DD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnDemandDiscard_M
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM007_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetDemandPendingForDiscard] 
@WraehouseId AS INT
AS
BEGIN

    SELECT DISTINCT SCPTnDemand_M.TRNSCTN_ID AS DemandNo,SCPTnDemand_M.TRNSCTN_ID AS TRNSCTN_ID FROM SCPTnDemand_M
    INNER JOIN SCPTnDemand_D ON SCPTnDemand_D.PARENT_TRNSCTN_ID=SCPTnDemand_M.TRNSCTN_ID WHERE SCPTnDemand_M.IsActive=1 
	AND SCPTnDemand_M.WraehouseId=@WraehouseId AND (SELECT COUNT(SCPTnDemand_D.ItemCode)
	FROM SCPTnDemand_D WHERE SCPTnDemand_D.PARENT_TRNSCTN_ID=SCPTnDemand_M.TRNSCTN_ID AND SCPTnDemand_D.PendingQty>0)>0
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM008_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceForReceiving]
@IssuenceNo as varchar(50),
@WraehouseId as int
AS
BEGIN
	--SELECT  SCPTnPharmacyIssuance_D.DemandId, SCPTnPharmacyIssuance_D.ItemCode, SCPStItem_M.ItemName, SCPTnPharmacyIssuance_D.DemandQty, SCPTnPharmacyIssuance_D.IssueQty as RecievedQty, 
	--sum(ISNULL(SCPTnStock_D.ItemBalance,0)) AS BALANCE FROM  SCPTnPharmacyIssuance_D INNER JOIN SCPStItem_M ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode 
	--LEFT OUTER JOIN SCPTnStock_D ON SCPTnPharmacyIssuance_D.ItemCode = SCPTnStock_D.ItemCode AND SCPTnStock_D.StockId=(SELECT MAX(StockId) FROM SCPTnStock_D where 
	--ItemCode=SCPTnPharmacyIssuance_D.ItemCode and BatchNo=SCPTnStock_D.BatchNo and WraehouseId=@WraehouseId) where SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=@IssuenceNo
	--group by SCPTnPharmacyIssuance_D.DemandId, SCPTnPharmacyIssuance_D.ItemCode, SCPStItem_M.ItemName, SCPTnPharmacyIssuance_D.DemandQty, SCPTnPharmacyIssuance_D.IssueQty

	--SELECT  SCPTnPharmacyIssuance_D.DemandId, SCPTnPharmacyIssuance_D.ItemCode, SCPStItem_M.ItemName, SCPTnPharmacyIssuance_D.DemandQty, SCPTnPharmacyIssuance_D.IssueQty as RecievedQty, 
	--isnull((select sum(c.ItemBalance) as ItemBalance from SCPTnStock_D as c where c.StockId=(SELECT MAX(StockId) FROM
	--SCPTnStock_D where ItemCode=c.ItemCode and BatchNo=c.BatchNo and WraehouseId=@WraehouseId) and c.ItemCode=SCPTnPharmacyIssuance_D.ItemCode	
	--group by c.ItemCode),0) as BALANCE FROM  SCPTnPharmacyIssuance_D INNER JOIN SCPStItem_M ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode 
	--where SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=@IssuenceNo	group by SCPTnPharmacyIssuance_D.DemandId, SCPTnPharmacyIssuance_D.ItemCode, SCPStItem_M.ItemName, SCPTnPharmacyIssuance_D.DemandQty, SCPTnPharmacyIssuance_D.IssueQty

	SELECT SCPTnPharmacyIssuance_D.DemandId,SCPTnPharmacyIssuance_D.ItemCode,SCPStItem_M.ItemName,SCPTnPharmacyIssuance_D.DemandQty,SCPTnPharmacyIssuance_D.IssueQty as RecievedQty,isnull((select sum(c.CurrentStock)
	as ItemBalance from SCPTnStock_M as c where ItemCode=SCPTnPharmacyIssuance_D.ItemCode and WraehouseId=@WraehouseId),0) as BALANCE FROM SCPTnPharmacyIssuance_D INNER JOIN SCPStItem_M
	ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode where SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=@IssuenceNo and SCPStItem_M.IsActive=1
	group by SCPTnPharmacyIssuance_D.DemandId, SCPTnPharmacyIssuance_D.ItemCode, SCPStItem_M.ItemName,
	SCPTnPharmacyIssuance_D.DemandQty,SCPTnPharmacyIssuance_D.IssueQty

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM008_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceReceiving_M] 
@trnsctnId as varchar(50)

AS
BEGIN
	
  SELECT TRNSCTN_DATE,FromWarehouseId,ToWarehouseId,PharmacyIssuanceId FROM SCPTnPharmacyReceiving_M where TRNSCTN_ID=@trnsctnId 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM008_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceReceiving_D]
@ParentId as varchar(50)
AS
BEGIN
	  select SCPTnPharmacyReceiving_D.DemandId,SCPTnPharmacyReceiving_D.ItemCode,SCPStItem_M.ItemName,
	  SCPTnPharmacyReceiving_D.ItemBalance,SCPTnPharmacyReceiving_D.DemandQty,SCPTnPharmacyReceiving_D.RecievedQty 
	  from SCPTnPharmacyReceiving_D 
	  INNER JOIN SCPStItem_M ON SCPTnPharmacyReceiving_D.ItemCode = SCPStItem_M.ItemCode and SCPStItem_M.IsActive=1 
	  where PARENT_TRNSCTN_ID=@ParentId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM008_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateIssuanceReceivingNo]
AS
BEGIN
	SELECT 'RC-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnPharmacyReceiving_M 
	WHERE MONTH(TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(TRNSCTN_DATE) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM008_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetIssuanceReceivingForSearch]
@Search as varchar(50)
AS
BEGIN
	select TRNSCTN_ID,SCPStWraehouse.WraehouseName as FromWarehouseId ,(select WraehouseName from SCPStWraehouse where WraehouseId=SCPTnPharmacyReceiving_M.ToWarehouseId) as ToWarehouseId,
	TRNSCTN_DATE,PharmacyIssuanceId from SCPTnPharmacyReceiving_M INNER JOIN SCPStWraehouse ON SCPTnPharmacyReceiving_M.FromWarehouseId = SCPStWraehouse.WraehouseId
	where SCPTnPharmacyReceiving_M.TRNSCTN_ID like '%'+@Search+'%' 
	ORDER BY TRNSCTN_ID DESC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM011_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGet30DaysSaleNoForSearch] 
@Search as varchar(50)
	
AS
BEGIN
	 SELECT TRANS_ID AS TRANS_ID, TRANS_ID AS SINo 
	 FROM SCPTnSale_M WHERE IsActive=1 AND TRANS_ID like '%'+@Search+'%'
	 AND TRANS_DT BETWEEN DATEADD(MONTH,-1,GETDATE()) AND GETDATE()
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPHM011_RL]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetSaleRefundNoForSearch] 
@Search as varchar(50)
	
AS
BEGIN
	 SELECT TRNSCTN_ID AS TRANS_ID,TRNSCTN_ID AS SINo 
	 FROM SCPTnSaleRefund_M WHERE IsActive=1 AND TRNSCTN_ID like '%'+@Search+'%'
	 --AND TRNSCTN_DATE BETWEEN DATEADD(MONTH,-1,GETDATE()) AND GETDATE()
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPhysioAndNarcoticsSaleList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPhysioAndNarcoticsSaleList] 
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN
   SELECT SCPTnSale_M.SaleId,CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) AS TRANS_DT,SCPStConsultant.ConsultantName,
   NamePrefix+' '+FirstName+' '+LastName AS SCPTnInPatient_NM,SCPStPatientCategory.PatientCategoryName AS PatientTypeName,SCPStDosage.DosageName,
   SCPStItem_M.ItemName,SCPTnSale_D.Quantity,SCPStManufactutrer.ManufacturerName,SCPTnSale_M.BatchNo,SCPStUser_M.UserName FROM SCPTnSale_M
   INNER JOIN SCPStConsultant ON SCPStConsultant.ConsultantId = SCPTnSale_M.ConsultantId
   INNER JOIN SCPStPatientCategory ON SCPStPatientCategory.PatientCategoryId = SCPTnSale_M.PatientCategoryId
   INNER JOIN SCPTnSale_D ON SCPTnSale_D.SaleId=SCPTnSale_M.SaleId
   INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnSale_D.ItemCode
   INNER JOIN SCPStDosage ON SCPStDosage.DosageId = SCPStItem_M.DosageFormId
   INNER JOIN SCPStManufactutrer ON SCPStManufactutrer.ManufacturerId=SCPStItem_M.ManufacturerId
   INNER JOIN SCPTnBatchNo_M ON SCPTnBatchNo_M.BatchNo=SCPTnSale_M.BatchNo
   INNER JOIN SCPStUser_M ON SCPTnBatchNo_M.UserId = SCPStUser_M.UserId
   WHERE SCPStItem_M.SubClassId IN(154,156,161) AND cast(SCPTnSale_M.TRANS_DT as date) 
   BETWEEN cast(CONVERT(date,@FromDate,103) as date) AND cast(CONVERT(date,@ToDate,103) as date)
    and SCPTnSale_M.IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPrAvg]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetPurchaseRequisitionAvgAmount]

AS BEGIN

	SELECT AVG(MANUAL_AMT) AS MANUAL_PR_AMT,AVG(AUTO_AMT) AS AUTO_PR_AMT FROM
	(
		SELECT DAY_DATE,ISNULL(SUM(MANUAL_AMT),0) AS MANUAL_AMT,ISNULL(SUM(AUTO_AMT),0) AS AUTO_AMT FROM
		(
			SELECT CAST(TRANSCTN_DT AS DATE) DAY_DATE,CASE WHEN PRCRMNT_TYPE='A' THEN SUM(DD.RequestedQty*CostPrice) END AS AUTO_AMT,
			CASE WHEN PRCRMNT_TYPE='M' THEN SUM(DD.RequestedQty*CostPrice) END AS MANUAL_AMT FROM SCPTnPurchaseRequisition_M MM
			INNER JOIN SCPTnPurchaseRequisition_D DD ON MM.TRANSCTN_ID = DD.PARENT_TRANS_ID
			LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = DD.ItemCode AND PRIC.FromDate <= TRANSCTN_DT and PRIC.ToDate >= TRANSCTN_DT
			WHERE CAST(TRANSCTN_DT AS DATE) BETWEEN DATEADD(DAY,-30,GETDATE()) AND GETDATE() AND MM.IsActive=1
			GROUP BY CAST(TRANSCTN_DT AS DATE),PRCRMNT_TYPE
		)TMP GROUP BY DAY_DATE
	)TMPP

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC001_CR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisition]

AS
BEGIN
SELECT a.TRANSCTN_ID as PurchaseReqNo,d.WraehouseName,a.TRANSCTN_DT as PRDate ,b.ItemCode,c.ItemName as ItemDesc,b.RequestedQty ,e.UnitName,
CASE WHEN a.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus 
FROM SCPTnPurchaseRequisition_M as a
Inner Join SCPTnPurchaseRequisition_D  b on a.TRANSCTN_ID = b.PARENT_TRANS_ID 
Inner Join SCPStItem_M c on b.ItemCode = c.ItemCode
Inner Join SCPStWraehouse d on a.WraehouseId = d.WraehouseId
Inner Join SCPStMeasuringUnit e on c.ItemUnit=e.UnitId



END

















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnPurchaseRequisition_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisition_M]
@Trnsctn_ID as VARCHAR(50)

AS
BEGIN
	 SELECT TRANSCTN_ID,TRANSCTN_DT,ProcurementId,WraehouseId, Priority,IsApprove
     FROM  SCPTnPurchaseRequisition_M where TRANSCTN_ID=@Trnsctn_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPTnPurchaseRequisition_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[Sp_SCPGetPurchaseRequisition_D]
(
@ParentId VARCHAR(50))
AS
begin

SELECT D.TRANS_ID,D.ItemCode,D.CurrentStock,D.MinLevel,d.MaxLevel,RequestedQty,ISNULL(PD.OrderQty,0) AS OrderQty,
D.PendingQty AS PEN_QTY,isnull(ReasonId,0) as ReasonId FROM SCPTnPurchaseRequisition_D D
LEFT OUTER JOIN SCPTnPurchaseOrder_D PD ON PD.ItemCode = D.ItemCode AND PD.PurchaseRequisitionId = D.PARENT_TRANS_ID
WHERE D.PARENT_TRANS_ID = @ParentId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC001_G]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[Sp_SCPGetManualPRItem]
(
@name varchar(50),
@WraehouseId as int
)

AS
BEGIN
--select p.ItemCode ,isnull(pd.MaxLevel,0) as MaxLevel ,isnull(pd.MinLevel,0) as MinLevel,isnull((select sum(c.CurrentStock) 
--as ItemBalance from SCPTnStock_M as c where ItemCode=p.ItemCode and WraehouseId=@WraehouseId),0) as CurrentStock from SCPStItem_M P
--left outer join SCPStParLevelAssignment_D pd on pd.ItemCode=p.ItemCode and pd.TRNSCTN_ID=(select max(x.TRNSCTN_ID) from SCPStParLevelAssignment_D x where 
--x.ItemCode=pd.ItemCode ) where P.ItemCode=@name 

SELECT ItemCode,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CurrentStock FROM
(
select p.ItemCode ,
CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,
isnull(SUM(c.CurrentStock),0) AS CurrentStock FROM SCPStItem_M P
INNER JOIN SCPStItem_D_WraehouseName ON P.ItemCode=SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId=@WraehouseId
LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=P.ItemCode AND c.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = P.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=SCPStItem_D_WraehouseName.WraehouseId
INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode AND WraehouseId = @WraehouseId) 
WHERE P.ItemCode=@name and P.IsActive=1 GROUP BY p.ItemCode,SCPStParLevelAssignment_D.ParLevelId,SCPStParLevelAssignment_D.NewLevel
)TMP GROUP BY ItemCode,CurrentStock  


END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC001_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[Sp_SCPGeneratePurchaseRequisitionNo]
AS
BEGIN




	SELECT 'PR-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(FB.TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
       FROM SCPTnPurchaseRequisition_M FB
	   	   WHERE MONTH(FB.TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(FB.TRANSCTN_DT) = YEAR(getdate())

	end


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC001_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPurchaseRequisition]
@PR as varchar(50)
AS
BEGIN
SELECT a.TRANSCTN_ID as PurchaseReqNo,
	   d.WraehouseName,
	   a.TRANSCTN_DT as PRDate,
	   b.ItemCode,
	   c.ItemName as ItemDesc,
	   b.RequestedQty ,
	   e.UnitName,
	   CASE WHEN a.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus,
	   CASE WHEN a.PRCRMNT_TYPE = 'M' THEN ' ' WHEN a.PRCRMNT_TYPE = 'A' THEN '(Auto)' END AS PR_Type

FROM SCPTnPurchaseRequisition_M as a
Inner Join SCPTnPurchaseRequisition_D  b on a.TRANSCTN_ID = b.PARENT_TRANS_ID 
Inner Join SCPStItem_M c on b.ItemCode = c.ItemCode
Inner Join SCPStWraehouse d on a.WraehouseId = d.WraehouseId
Inner Join SCPStMeasuringUnit e on c.ItemUnit=e.UnitId
WHERE a.TRANSCTN_ID =@PR

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC001_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionForSearch]
@Trnsctn_ID as varchar(50),
@TypeId as int

AS
BEGIN

	SELECT CA.TRANSCTN_ID, CA.TRANSCTN_DT,SCPStProcurementNameType.ProcurementName FROM SCPTnPurchaseRequisition_M CA 
    inner join SCPStProcurementNameType on SCPStProcurementNameType.ProcurementNameId=ca.ProcurementId
    where CA.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' AND CA.PRCRMNT_TYPE='M'
	AND CA.ProcurementId=@TypeId 
	ORDER BY CA.TRANSCTN_ID DESC

END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPGetPurchaseRequisitionPendingItemList] 
@PR_NO AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnPurchaseRequisition_D.ItemCode,SCPStItem_M.ItemName FROM SCPTnPurchaseRequisition_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPurchaseRequisition_D.ItemCode and SCPStItem_M.IsActive=1
    WHERE SCPTnPurchaseRequisition_D.PendingQty>0 AND SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=@PR_NO
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPGetPurchaseRequisitionPendingItemDetail]
@PR_N0 AS VARCHAR(50),
@ITEM_ID AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnPurchaseRequisition_D.RequestedQty,SCPTnPurchaseRequisition_D.PendingQty,SCPTnPurchaseRequisition_D.DiscardQty 
	FROM SCPTnPurchaseRequisition_D
    WHERE SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=@PR_N0 AND SCPTnPurchaseRequisition_D.ItemCode=@ITEM_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_M] 
@TRNSCTN_ID AS VARCHAR(50)
AS
BEGIN
	 SELECT TRANSCTN_DT,WraehouseId,PurchaseRequisitionId FROM SCPTnPurchaseRequisitionDiscard_M
     WHERE TRANSCTN_ID=@TRNSCTN_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscard_D]
@PARENT_ID AS VARCHAR(50)
AS
BEGIN
	 SELECT ItemCode,RequestedQty,PendingQty,DiscardQty,RemainingQty,DiscardReasonId,ISNULL(DiscardReasonId,'') AS DiscardReasonId
	 FROM SCPTnPRDiscard_D WHERE PARENT_TRNSCTN_ID=@PARENT_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPPGetPurchaseRequisitionPendingAllItems]
@PR_N0 AS VARCHAR(50)
AS
BEGIN
	

		SELECT SCPTnPurchaseRequisition_D.ItemCode,SCPStItem_M.ItemName,SCPTnPurchaseRequisition_D.RequestedQty,
		SCPTnPurchaseRequisition_D.PendingQty,SCPTnPurchaseRequisition_D.DiscardQty  FROM SCPTnPurchaseRequisition_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPurchaseRequisition_D.ItemCode and SCPStItem_M.IsActive=1
    WHERE SCPTnPurchaseRequisition_D.PendingQty>0 AND SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=@PR_N0

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePurchaseRequisitionDiscardNo]
AS
BEGIN
	SELECT 'PD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRANSCTN_ID
    FROM SCPTnPurchaseRequisitionDiscard_M 
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionPendingList] 
@WraehouseId AS INT
AS
BEGIN
	--SELECT DISTINCT SCPTnPurchaseRequisition_M.TRANSCTN_ID AS PRID,SCPTnPurchaseRequisition_M.TRANSCTN_ID AS PRN FROM SCPTnPurchaseRequisition_M
 --   INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=SCPTnPurchaseRequisition_M.TRANSCTN_ID
 --   WHERE SCPTnPurchaseRequisition_M.IsActive=1 AND SCPTnPurchaseRequisition_M.IsReject=0 AND SCPTnPurchaseRequisition_M.WraehouseId=@WraehouseId
 --   AND (SELECT COUNT(SCPTnPurchaseRequisition_D.ItemCode) FROM SCPTnPurchaseRequisition_D
 --   LEFT OUTER JOIN SCPTnPurchaseOrder_D ON SCPTnPurchaseOrder_D.PurchaseRequisitionId=SCPTnPurchaseRequisition_D.PARENT_TRANS_ID 
	--AND SCPTnPurchaseRequisition_D.ItemCode=SCPTnPurchaseOrder_D.ItemCode WHERE SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=SCPTnPurchaseRequisition_M.TRANSCTN_ID
	--AND (SCPTnPurchaseRequisition_D.RequestedQty-ISNULL(SCPTnPurchaseOrder_D.OrderQty,0))>0)>0


	SELECT DISTINCT SCPTnPurchaseRequisition_M.TRANSCTN_ID AS PRID,SCPTnPurchaseRequisition_M.TRANSCTN_ID AS PRN FROM SCPTnPurchaseRequisition_M
    INNER JOIN SCPTnPurchaseRequisition_D ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=SCPTnPurchaseRequisition_M.TRANSCTN_ID WHERE SCPTnPurchaseRequisition_M.IsActive=1 
	AND SCPTnPurchaseRequisition_M.IsReject=0 AND SCPTnPurchaseRequisition_M.WraehouseId=@WraehouseId AND (SELECT COUNT(SCPTnPurchaseRequisition_D.ItemCode)
	FROM SCPTnPurchaseRequisition_D WHERE SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=SCPTnPurchaseRequisition_M.TRANSCTN_ID AND SCPTnPurchaseRequisition_D.PendingQty>0 )>0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC002_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionDiscardForSearch] 
@SEARCH AS VARCHAR(50)
AS
BEGIN
	SELECT TRANSCTN_ID,TRANSCTN_DT,PurchaseRequisitionId,SCPStWraehouse.WraehouseName FROM SCPTnPurchaseRequisitionDiscard_M
    INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId=SCPTnPurchaseRequisitionDiscard_M.WraehouseId WHERE TRANSCTN_ID LIKE '%'+@SEARCH+'%' 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderPendingItemDetail]
@PO_N0 AS VARCHAR(50),
@ITEM_ID AS VARCHAR(50)
AS
BEGIN
	SELECT sum(SCPTnPurchaseOrder_D.OrderQty) as OrderQty,sum(SCPTnPurchaseOrder_D.PendingQty) as PendingQty,
    sum(SCPTnPurchaseOrder_D.DiscardQty) as DiscardQty FROM SCPTnPurchaseOrder_D 
	 INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPurchaseOrder_D.ItemCode and SCPStItem_M.IsActive=1
	WHERE SCPTnPurchaseOrder_D.PurchaseOrderId=@PO_N0 
	AND SCPTnPurchaseOrder_D.ItemCode=@ITEM_ID
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderDiscard_M]
@TransactionId  AS VARCHAR(50)
AS
BEGIN
	  SELECT TRANSCTN_DT,WraehouseId,SupplierId,PurchaseOrderId FROM SCPTnPurchaseOrderDiscard_M WHERE TRANSCTN_ID=@TransactionId
	  AND IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderDiscard_D]
@TransactionId  AS VARCHAR(50)
AS
BEGIN
	 SELECT ItemCode,OrderQty,PendingQty,DiscardQty,RemainingQty,DiscardReasonId,DiscardReasonId FROM SCPTnPurchaseOrderDiscard_D WHERE PARENT_TRNSCTN_ID=@TransactionId
     AND IsActive=1
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderPendingAllItemForDiscard]
@PO_N0 AS VARCHAR(50)
AS
BEGIN
	SELECT SCPTnPurchaseOrder_D.ItemCode as ItemCode, SCPStItem_M.ItemName AS ItemName, 
	SUM(SCPTnPurchaseOrder_D.OrderQty) as OrderQty,SUM(SCPTnPurchaseOrder_D.PendingQty) as PendingQty,
    SUM(SCPTnPurchaseOrder_D.DiscardQty) as DiscardQty FROM SCPTnPurchaseOrder_D 
	 INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPurchaseOrder_D.ItemCode and SCPStItem_M.IsActive=1
	WHERE 
	SCPTnPurchaseOrder_D.PurchaseOrderId= @PO_N0 AND SCPTnPurchaseOrder_D.PendingQty != 0
	group by SCPStItem_M.ItemName ,SCPTnPurchaseOrder_D.ItemCode
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePurchaseOrderDiscardNo]
AS
BEGIN
	SELECT 'PD-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRANSCTN_ID)+1 AS VARCHAR(6)),5) AS TRANSCTN_ID
    FROM SCPTnPurchaseOrderDiscard_M 
	WHERE MONTH(TRANSCTN_DT) = MONTH(getdate())
    AND YEAR(TRANSCTN_DT) = YEAR(getdate())
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC003_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderPendingItemList]
@PurchaseOrderId as varchar(50),
@ItemID as varchar(50)
AS
BEGIN
	SELECT PurchaseRequisitionId,PendingQty FROM SCPTnPurchaseOrder_D WHERE PARENT_TRNSCTN_ID=@PurchaseOrderId AND ItemCode=@ItemID AND PendingQty>0
END


GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderPendingAllItemForGRN]
@PurchaseOrder as varchar(50)
AS
BEGIN
         SELECT SCPTnPurchaseOrder_D.ItemCode, SCPStItem_M.ItemName,sum(SCPTnPurchaseOrder_D.PendingQty) as OrderQty,0 AS PendingQty, 
         max(SCPTnPurchaseOrder_D.ItemRate) as ItemRate,ISNULL(SCPStRate.SalePrice,0) AS SalePrice, sum(SCPTnPurchaseOrder_D.NetAmount) as NetAmount FROM SCPStItem_M 
         INNER JOIN SCPTnPurchaseOrder_D ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
		 LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode=SCPTnPurchaseOrder_D.ItemCode 
		 where SCPTnPurchaseOrder_D.PurchaseOrderId=@PurchaseOrder
		 AND CONVERT(date, getdate()) between FromDate and ToDate
		 and SCPStItem_M.IsActive=1
         GROUP BY SCPTnPurchaseOrder_D.ItemCode,SCPStItem_M.ItemName,SCPStRate.SalePrice
		  having sum(SCPTnPurchaseOrder_D.PendingQty)>0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderItemList]
@PurchaseOrder as varchar(50)
AS
BEGIN
	SELECT SCPTnPurchaseOrder_D.ItemCode, SCPStItem_M.ItemName
    FROM SCPStItem_M 
	INNER JOIN SCPTnPurchaseOrder_D ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode 
	where SCPTnPurchaseOrder_D.PurchaseOrderId=@PurchaseOrder
	and SCPStItem_M.IsActive=1
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPrchaseRequsitionItemsBySUpplier]
@WraehouseId as int,
@SupplierId as int,
@Price as varchar(50)
AS
BEGIN

select ItemCode,ItemName,RequestedQty,PEN_QTY,ItemPackingQuantity,CASE WHEN PEN_QTY<=ItemPackingQuantity THEN ItemPackingQuantity ELSE
 (ROUND( CAST(PEN_QTY AS float) / CAST(ItemPackingQuantity AS float),0)*ItemPackingQuantity) END as OrderQty,Price
   from
   (
     select ItemCode,ItemName,SUM(RequestedQty) as RequestedQty,sum(PEN_QTY) as PEN_QTY,ItemPackingQuantity,Price from(
	 select distinct PARENT_TRANS_ID,a.ItemCode,c.ItemName,a.RequestedQty,a.PendingQty as PEN_QTY,ItemPackingQuantity,
	 CASE WHEN @Price='PP' THEN isnull(d.CostPrice,0) ELSE D.TradePrice END  as Price
	  from SCPTnPurchaseRequisition_D as a 
	 left join SCPStItem_M as c on a.ItemCode=c.ItemCode and c.IsActive=1
	 inner join SCPStRate d on c.ItemCode = d.ItemCode and d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	 where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode) 
	 Inner Join SCPStItem_D_Supplier ON a.ItemCode=SCPStItem_D_Supplier.ItemCode and SCPStItem_D_Supplier.IsActive=1
	 where SCPStItem_D_Supplier.SupplierId=@SupplierId and a.PARENT_TRANS_ID IN (select TRANSCTN_ID from SCPTnPurchaseRequisition_M where IsActive=1 and
	 IsApprove=1 and IsReject=0 and WraehouseId=@WraehouseId) and a.PendingQty>0 
	   )tmpo group by ItemCode,ItemName,ItemPackingQuantity,Price
   ) 
    tmp

end


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D2New]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE proc [dbo].[Sp_SCPGetPurchaseRequisitionBySupplier]
@SuppId as int,
@ParentId as varchar(50),
@Price as varchar(50)
AS
BEGIN
if(@Price='PP')
begin
select a.PARENT_TRANS_ID,a.ItemCode,a.PEN_QTY,a.RequestedQty,c.ItemName,d.CostPrice as Price,x.SupplierId
from SCPTnPurchaseRequisition_D as a 
left join SCPStItem_M as c on a.ItemCode=c.ItemCode
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE a.PARENT_TRANS_ID=@ParentId and x.SupplierId=@SuppId  and a.ItemCode not IN 
  (SELECT distinct b.ItemCode FROM SCPTnPurchaseOrder_D as b where a.PARENT_TRANS_ID=b.PurchaseRequisitionId)
  end
  else
  begin
 select a.PARENT_TRANS_ID,a.ItemCode,a.PEN_QTY,a.RequestedQty,c.ItemName,d.CostPrice as Price,x.SupplierId
from SCPTnPurchaseRequisition_D as a 
left join SCPStItem_M as c on a.ItemCode=c.ItemCode
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE a.PARENT_TRANS_ID=@ParentId and x.SupplierId=@SuppId  and a.ItemCode not IN 
  (SELECT distinct b.ItemCode FROM SCPTnPurchaseOrder_D as b where a.PARENT_TRANS_ID=b.PurchaseRequisitionId)
END


end








GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrder_M]
@Trnsctn_ID as varchar(50)
AS
BEGIN
	SELECT DISTINCT a.TRNSCTN_ID, 
		   a.TRNSCTN_DATE,
		   a.SupplierId,
		   a.WarehouseId,
		   SCPStWraehouse.ItemTypeId,
		   a.ItemRate,
		   a.TotalAmount,
		   IsApprove,IsReject,
		   Vendor.SupplierLongName
FROM  SCPTnPurchaseOrder_M as a
INNER JOIN SCPStSupplier AS Vendor ON Vendor.SupplierId = a.SupplierId
INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId = a.WarehouseId
 where a.TRNSCTN_ID=@Trnsctn_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetPurchaseOrder_D]
(
@ParentId varchar(50))
AS
BEGIN

select a.ItemCode,ItemName,a.ItemRate, a.BonusQty,sum(a.RequestedQty) as RequestedQty,ItemPackingQuantity,
sum(a.OrderQty) as OrderQty,--(sum(a.RequestedQty)-sum(a.OrderQty)) as PendingQty,
sum(a.PendingQty) as PendingQty,sum(a.NetAmount)  as NetAmount from SCPTnPurchaseOrder_D as a
INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = a.ItemCode and SCPStItem_M.IsActive=1
 where a.PARENT_TRNSCTN_ID=@ParentId
group by a.ItemCode,ItemName,a.ItemRate, a.BonusQty,ItemPackingQuantity

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE proc [dbo].[Sp_SCPGetPurchaseOrder]
(
@ParentId varchar(50))
AS
BEGIN

--select a.PARENT_TRNSCTN_ID,a.ItemCode,a.OrderQty,b.OrderQty,case when b.OrderQty is not null then'Completed' else 'Pending'end as StatusQTY 
--from SCPTnPurchaseOrder_D as a
--left join SCPTnPharmacyIssuance_M x on x.PurchaseOrderId=a.PARENT_TRNSCTN_ID
--left  join SCPTnPharmacyIssuance_D as b on b.PARENT_TRNSCTN_ID=x.TRNSCTN_ID  and a.ItemCode=b.ItemCode
--where a.PARENT_TRNSCTN_ID=@ParentId

select a.PARENT_TRNSCTN_ID,a.ItemCode,isnull(sum(a.OrderQty),0) as OrderQty,isnull(sum(b.RecievedQty),0) as RecievedQty,
case when sum(b.RecievedQty)=sum(a.OrderQty) then'Completed' when sum(b.RecievedQty)!=0 then'Process' 
else 'Pending' end as StatusQTY from SCPTnPurchaseOrder_D as a
left join SCPTnGoodReceiptNote_M x on x.PurchaseOrderId=a.PARENT_TRNSCTN_ID
left  join SCPTnGoodReceiptNote_D as b on b.PARENT_TRNSCTN_ID=x.TRNSCTN_ID  and a.ItemCode=b.ItemCode
where a.PARENT_TRNSCTN_ID=@ParentId
Group By a.PARENT_TRNSCTN_ID,a.ItemCode
END












GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_D6]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE proc [dbo].[Sp_SCPGetPurchaseOrderItemRates] 
@SuppId as int,
@WId as varchar(50),
@Price as varchar(50)
AS
BEGIN
if(@Price='PP')
begin
select c.ItemCode,c.ItemName,d.CostPrice as Price,x.SupplierId,z.WraehouseId
from SCPStItem_M as c 
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStItem_D_WraehouseName z on  z.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE z.WraehouseId=@WId  and x.SupplierId=@SuppId  and x.IsActive=1
  end
  else
  begin
select c.ItemCode,c.ItemName,d.TradePrice as Price,x.SupplierId,z.WraehouseId
from SCPStItem_M as c 
inner join SCPStItem_D_Supplier x on x.ItemCode=c.ItemCode
inner join SCPStItem_D_WraehouseName z on  z.ItemCode=c.ItemCode
inner join SCPStRate d on  c.ItemCode = d.ItemCode and 
	d.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=c.ItemCode)
WHERE z.WraehouseId=@WId  and x.SupplierId=@SuppId  and x.IsActive=1
END


end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGeneratePurchaseOrderId]

AS
BEGIN
	SELECT 'PO-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(FB.TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS PONo
       FROM SCPTnPurchaseOrder_M FB
	   	   WHERE MONTH(FB.TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(FB.TRNSCTN_DATE) = YEAR(getdate())
END





GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPPurchaseOrderPendingList]
@WraehouseId as INT,
@SPLR_ID AS INT
AS
BEGIN

    WITH CTE AS
     (
	   select PARENT_TRNSCTN_ID,SupplierShortName,ItemCode,ItemName,OrderQty
     from
     (
        SELECT SCPTnPurchaseOrder_D.PurchaseOrderId,SCPStSupplier.SupplierShortName,SCPTnPurchaseOrder_D.ItemCode, SCPStItem_M.ItemName,
	    SCPTnPurchaseOrder_D.PendingQty AS OrderQty FROM SCPStItem_M 
		INNER JOIN SCPTnPurchaseOrder_D ON SCPStItem_M.ItemCode = SCPTnPurchaseOrder_D.ItemCode
		INNER JOIN SCPTnPurchaseOrder_M ON SCPTnPurchaseOrder_M.TRNSCTN_ID=SCPTnPurchaseOrder_D.PurchaseOrderId 
		ANd SCPTnPurchaseOrder_M.WarehouseId=@WraehouseId 
		AND SCPTnPurchaseOrder_M.SupplierId=@SPLR_ID	AND SCPTnPurchaseOrder_M.IsActive=1 and SCPTnPurchaseOrder_M.IsApprove=1 --and SCPTnPurchaseOrder_M.IsReject=0
        INNER JOIN SCPStSupplier ON SCPTnPurchaseOrder_M.SupplierId=SCPStSupplier.SupplierId
		where SCPStItem_M.IsActive=1
      ) 
      tmp 
	    ) 
	    SELECT DISTINCT PARENT_TRNSCTN_ID as TRNSCTN_ID,PARENT_TRNSCTN_ID as PONo
	    FROM CTE WHERE isnull(OrderQty,0)>0 

  --      Union

	 --   SELECT TRNSCTN_ID,TRNSCTN_ID+' || '+SCPStSupplier.SupplierShortName as PONo FROM SCPTnPurchaseOrder_M 
	 --   INNER JOIN SCPStSupplier ON SCPTnPurchaseOrder_M.SupplierId=SCPStSupplier.SupplierId 
	 --   where TRNSCTN_ID Not IN(select PurchaseOrderId from SCPTnPharmacyIssuance_M ) and SCPTnPurchaseOrder_M.IsActive=1 and 
		--SCPTnPurchaseOrder_M.IsApprove=1 and SCPTnPurchaseOrder_M.IsReject=0 and SCPTnPurchaseOrder_M.WarehouseId=@WraehouseId AND SCPTnPurchaseOrder_M.SupplierId=@SPLR_ID


END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L10]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseRequsitionItemDetail]
@ParentId as varchar(50),
@ItemId as varchar(50)
AS
BEGIN
	 select isnull(PurchaseRequisitionId,0) as PurchaseRequisitionId,OrderQty,RequestedQty,
	 isnull(SCPTnPurchaseRequisition_D.PendingQty,0) as PendingQty from SCPTnPurchaseOrder_D
	  left outer join SCPTnPurchaseRequisition_D on SCPTnPurchaseRequisition_D.PARENT_TRANS_ID = SCPTnPurchaseOrder_D.PurchaseRequisitionId 
	  and SCPTnPurchaseRequisition_D.ItemCode=SCPTnPurchaseOrder_D.ItemCode
	  where PARENT_TRNSCTN_ID=@ParentId and SCPTnPurchaseOrder_D.ItemCode=@ItemId  
	  order by SCPTnPurchaseOrder_D.TRNSCTN_ID desc
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L4]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[Sp_SCPGetItemRateOnForPO]
@ITemId as varchar(50),
@Price as varchar(50)
AS
BEGIN
if(@Price='PP')
begin
	SELECT SCPStItem_M.ItemCode, SCPStRate.CostPrice as Prize
	FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
	SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	where SCPStItem_M.ItemCode=@ITemId and SCPStItem_M.IsActive=1


  end
  else
  begin
SELECT SCPStItem_M.ItemCode,SCPStRate.TradePrice as Prize
	FROM SCPStItem_M INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode and 
	SCPStRate.ItemRateId=(select isnull(Max(ItemRateId),0) from SCPStRate 
	where CONVERT(date, getdate()) between FromDate and ToDate and SCPStRate.ItemCode=SCPStItem_M.ItemCode)
	where SCPStItem_M.ItemCode=@ITemId and SCPStItem_M.IsActive=1


END


end








GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L5]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderForSearch]
@Trnsctn_ID as varchar(50),
@paramWraehouseId INT
AS
BEGIN
		SELECT a.TRNSCTN_ID,a.TRNSCTN_DATE,a.SupplierId,a.WarehouseId,y.WraehouseName,x.SupplierShortName,SupplierLongName
FROM  SCPTnPurchaseOrder_M as a		
INNER JOIN SCPStWraehouse y ON a.WarehouseId= y.WraehouseId
INNER JOIN SCPStSupplier x ON a.SupplierId = x.SupplierId
 where a.TRNSCTN_ID LIKE '%'+@Trnsctn_ID+'%' AND y.WraehouseId = @paramWraehouseId
 ORDER BY A.TRNSCTN_ID DESC
END
GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L7]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderSupplier]
@transactionId as varchar(50)
AS
BEGIN
	 select SupplierId from SCPTnPurchaseOrder_M where TRNSCTN_ID=@transactionId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L8]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderPendingList] 
@ItemId as varchar(50),
@WraehouseId  as int
AS
BEGIN

   --select SCPTnPurchaseRequisition_D.PARENT_TRANS_ID,(SCPTnPurchaseRequisition_D.RequestedQty-isnull(sum(SCPTnPurchaseOrder_D.OrderQty),0)) as OrderQty 
   --from SCPTnPurchaseRequisition_D Inner Join SCPTnPurchaseRequisition_M ON SCPTnPurchaseRequisition_D.PARENT_TRANS_ID=SCPTnPurchaseRequisition_M.TRANSCTN_ID Left Outer join 
   --SCPTnPurchaseOrder_D ON SCPTnPurchaseOrder_D.PurchaseRequisitionId=SCPTnPurchaseRequisition_D.PARENT_TRANS_ID where SCPTnPurchaseRequisition_D.ItemCode=@ItemId and SCPTnPurchaseRequisition_M.WraehouseId=@WraehouseId 
   --and IsApprove=1 and PR_Status!='Completed' group by SCPTnPurchaseRequisition_D.PARENT_TRANS_ID,SCPTnPurchaseRequisition_D.RequestedQty
   --having (SCPTnPurchaseRequisition_D.RequestedQty-isnull(sum(SCPTnPurchaseOrder_D.OrderQty),0))>0

   select SCPTnPurchaseRequisition_D.PARENT_TRANS_ID,SCPTnPurchaseRequisition_D.ItemCode,
   SCPTnPurchaseRequisition_D.PendingQty as OrderQty from SCPTnPurchaseRequisition_D 
   where SCPTnPurchaseRequisition_D.ItemCode=@ItemId 
   and SCPTnPurchaseRequisition_D.PARENT_TRANS_ID IN (select TRANSCTN_ID from SCPTnPurchaseRequisition_M
   where IsApprove=1 and WraehouseId=@WraehouseId) and SCPTnPurchaseRequisition_D.PendingQty>0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_L9]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetPurchaseOrderQuantityByItem]
@ParentId as varchar(50),
@ItemId as varchar(50)
AS
BEGIN
	select isnull(sum(OrderQty),0) as OrderQty from SCPTnPurchaseOrder_D where PARENT_TRNSCTN_ID=@ParentId and ItemCode=@ItemId
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC004_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Author,,Tabish>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPurchaseOrder]
@PO as varchar(50)
AS
BEGIN
--SELECT a.TRNSCTN_ID as PO , a.TRNSCTN_DATE as PODate ,
--b.ItemCode,b.ItemRate,b.NetAmount,sum(b.OrderQty),c.ItemName,d.SupplierShortName,
--c.PackingQuantity as [UnitOfPacking],c.ItemPackingQuantity as [PackingSize],e.TRANSCTN_DT as[PRDate],CASE WHEN a.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus 
--FROM SCPTnPurchaseOrder_M as a
--INNER JOIN SCPTnPurchaseOrder_D b on a.TRNSCTN_ID = b.PARENT_TRNSCTN_ID
--Inner Join SCPStItem_M c on b.ItemCode = c.ItemCode
--INNER JOIN SCPStSupplier d on a.SupplierId=d.SupplierId
--INNER JOIN SCPTnPurchaseRequisition_M e on b.PurchaseRequisitionId = e.TRANSCTN_ID
--WHERE a.TRNSCTN_ID =@PO
--group by 
--a.TRNSCTN_ID  , a.TRNSCTN_DATE  ,
--b.ItemCode,b.ItemRate,b.NetAmount,c.ItemName,d.SupplierShortName,
--c.PackingQuantity ,c.ItemPackingQuantity ,e.TRANSCTN_DT,a.PrintDate

--	SELECT  POM.TRNSCTN_DATE as PODate ,
--	 POD.ItemRate, POD.NetAmount,  SUM(POD.OrderQty) as Quantity,
--	ITEM.ItemName, SUP.SupplierShortName, PR.TRANSCTN_ID,
--	ITEM.PackingQuantity as [UnitOfPacking],ITEM.ItemPackingQuantity as [PackingSize],PR.TRANSCTN_DT as[PRDate],
----CASE WHEN POM.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus, 
--			(CASE 
--				WHEN  SUM(POD.OrderQty) =  SUM(GRND.RecievedQty)
--				THEN 'Complete' 
--				WHEN SUM(POD.OrderQty) >  SUM(GRND.RecievedQty)
--				THEN 'Process'
--				WHEN SUM(POD.OrderQty) <  SUM(GRND.RecievedQty)
--				THEN 'Complete'
--				ELSE 'Pending'
--				END
--			) as Status
--		FROM SCPTnPurchaseOrder_D POD 
--		INNER JOIN SCPTnPurchaseOrder_M POM ON POM.TRNSCTN_ID = POD.PARENT_TRNSCTN_ID
--		Inner Join SCPStItem_M ITEM on POD.ItemCode = ITEM.ItemCode
--		INNER JOIN SCPStSupplier SUP on POM.SupplierId=SUP.SupplierId
--		INNER JOIN SCPTnPurchaseRequisition_M PR on POD.PurchaseRequisitionId = PR.TRANSCTN_ID
--		LEFT OUTER JOIN SCPTnPharmacyIssuance_D GRND ON GRND.ItemCode = POD.ItemCode
--		LEFT OUTER JOIN SCPTnPharmacyIssuance_M GRNM ON POM.TRNSCTN_ID = GRNM.PurchaseOrderId
--	WHERE POM.TRNSCTN_ID =@PO
--	GROUP BY POM.TRNSCTN_ID, POM.TRNSCTN_DATE,
--	POD.ItemCode, POD.ItemRate, POD.NetAmount,
--	ITEM.ItemName, SUP.SupplierShortName,
--	ITEM.PackingQuantity ,ITEM.ItemPackingQuantity,PR.TRANSCTN_DT ,
--	POM.TRNSCTN_ID,  GRND.ItemCode,POM.PrintDate ,PR.TRANSCTN_ID

--SELECT SPLR.SupplierShortName, PO_M.TRNSCTN_ID, PO_M.TRNSCTN_DATE, ITM.ItemName, ITM.PackingQuantity, ITM.ItemPackingQuantity,
--SUM(PO_D.OrderQty) as Quantity, PO_D.ItemRate, SUM(PO_D.NetAmount) as Item_amount,
--ISNULL('Pending',GRN_M.PurchaseOrderId) as Status,
----ISNULL('Pending',GRN_M.TRNSCTN_ID) as Status,
--CASE WHEN PO_M.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus
--FROM SCPStItem_M ITM
--INNER JOIN SCPTnPurchaseOrder_D PO_D ON PO_D.ItemCode = ITM.ItemCode
-- AND PO_D.IsActive = 1 AND PARENT_TRNSCTN_ID = @PO
--INNER JOIN SCPTnPurchaseOrder_M PO_M ON PO_M.TRNSCTN_ID = PO_D.PARENT_TRNSCTN_ID
--INNER JOIN SCPStSupplier SPLR ON SPLR.SupplierId = PO_M.SupplierId
--INNER JOIN SCPTnPharmacyIssuance_M GRN_M ON GRN_M.PurchaseOrderId = PO_M.TRNSCTN_ID 
--AND GRN_M.IsActive = 1
--GROUP BY SPLR.SupplierShortName, PO_M.TRNSCTN_ID, PO_M.TRNSCTN_DATE, ITM.ItemName, ITM.PackingQuantity, ITM.ItemPackingQuantity,
--PO_D.ItemRate,PO_M.PrintDate
--,GRN_M.PurchaseOrderId

SELECT SupplierLongName,TRNSCTN_ID,TRNSCTN_DATE,ItemCode,ItemName,PackingQuantity,ItemPackingQuantity,SUM(OrderQty) as Quantity,ItemRate,SUM(NetAmount) as Item_amount,
Status,PrintSatus FROM
(
SELECT Distinct SPLR.SupplierLongName, PO_M.TRNSCTN_ID,PO_D.PurchaseRequisitionId, PO_M.TRNSCTN_DATE, PO_D.ItemCode,ITM.ItemName, ITM.PackingQuantity, ITM.ItemPackingQuantity,
PO_D.OrderQty, PO_D.ItemRate, PO_D.NetAmount,
ISNULL('Pending',GRN_M.PurchaseOrderId) as Status,
CASE WHEN PO_M.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus
FROM SCPStItem_M ITM
INNER JOIN SCPTnPurchaseOrder_D PO_D ON PO_D.ItemCode = ITM.ItemCode
 AND PO_D.IsActive = 1 AND PARENT_TRNSCTN_ID = @PO
INNER JOIN SCPTnPurchaseOrder_M PO_M ON PO_M.TRNSCTN_ID = PO_D.PARENT_TRNSCTN_ID
INNER JOIN SCPStSupplier SPLR ON SPLR.SupplierId = PO_M.SupplierId
LEFT OUTER JOIN SCPTnGoodReceiptNote_M GRN_M ON GRN_M.PurchaseOrderId = PO_M.TRNSCTN_ID 
AND GRN_M.IsActive = 1
)TMP
GROUP BY SupplierLongName, TRNSCTN_ID, TRNSCTN_DATE, ItemCode,ItemName, PackingQuantity, ItemPackingQuantity,
ItemRate,Status,PrintSatus

END
GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodRecieptNote_D]
@Trnsctn_ID as varchar(50)

AS
BEGIN
	 SELECT SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId,SCPTnGoodReceiptNote_D.ItemCode, SCPStItem_M.ItemName, SCPTnGoodReceiptNote_D.OrderQty, SCPTnGoodReceiptNote_D.RecievedQty, 
	 BonusQty ,SCPTnGoodReceiptNote_D.PendingQty,SCPTnGoodReceiptNote_D.ItemRate, SCPTnGoodReceiptNote_D.TotalAmount, SCPTnGoodReceiptNote_D.DiscountType,
	 SCPTnGoodReceiptNote_D.DiscountValue,SCPTnGoodReceiptNote_D.SalePrice,SCPTnGoodReceiptNote_D.AfterDiscountAmount, SCPTnGoodReceiptNote_D.SaleTax, SCPTnGoodReceiptNote_D.NetAmount,
	 SCPTnGoodReceiptNote_D.ExpiryDate, SCPTnGoodReceiptNote_D.BatchNo FROM SCPTnGoodReceiptNote_D 
	 INNER JOIN SCPStItem_M ON SCPTnGoodReceiptNote_D.ItemCode = SCPStItem_M.ItemCode where SCPTnGoodReceiptNote_D.GoodReceiptNoteId=@Trnsctn_ID
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodRecieptNote_M]
@Trnsctn_ID as varchar(50)

AS
BEGIN
	 SELECT TRNSCTN_ID, TRNSCTN_DATE, SCPTnGoodReceiptNote_M.SupplierId,SCPTnGoodReceiptNote_M.WraehouseId,IsApproved ,PurchaseOrderId,SCPStWraehouse.ItemTypeId, 
	 SupplierLongName,
	 ChallanNo, ChallanDate,InvoiceNo,InvoiceDate, TotalAmount,GRNType,TotalSaleTax,
	 GRNAmount,TotalDiscount, NetAmount FROM SCPTnGoodReceiptNote_M
	 INNER JOIN SCPStWraehouse ON SCPStWraehouse.WraehouseId = SCPTnGoodReceiptNote_M.WraehouseId
	 INNER JOIN SCPStSupplier SUP ON SUP.SupplierId = SCPTnGoodReceiptNote_M.SupplierId
	 where SCPTnGoodReceiptNote_M.IsActive=1 and TRNSCTN_ID=@Trnsctn_ID
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetGoodRecieptNoteFreezItemDetail]
@PurchaseOrderId AS VARCHAR(50),
@ItemCode AS VARCHAR(50)
AS BEGIN

	SELECT sum(SCPTnPurchaseOrder_D.OrderQty) AS OrderQty, sum(SCPTnPurchaseOrder_D.PendingQty) AS PendingQty,
	ISNULL(IsFreez,0) AS IsFreez FROM SCPTnPurchaseOrder_D 
	LEFT OUTER JOIN SCPTnFreezItem ON PARENT_TRNSCTN_ID = PurchaseOrderId AND SCPTnPurchaseOrder_D.ItemCode = SCPTnFreezItem.ItemCode
	WHERE SCPTnPurchaseOrder_D.PurchaseOrderId=@PurchaseOrderId AND SCPTnPurchaseOrder_D.ItemCode=@ItemCode
	AND PARENT_TRNSCTN_ID IN(SELECT PurchaseOrderId FROM SCPTnGoodReceiptNote_M)
	GROUP BY SCPTnPurchaseOrder_D.PurchaseOrderId,SCPTnPurchaseOrder_D.ItemCode,IsFreez

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_D3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPGetGoodRecieptNoteFreezItem]
@PurchaseOrderId AS VARCHAR(50)
AS BEGIN
SELECT DISTINCT PO.PARENT_TRNSCTN_ID,PO.ItemCode FROM SCPTnPurchaseOrder_D PO 
INNER JOIN SCPTnGoodReceiptNote_M GRN ON GRN.PurchaseOrderId = PO.PARENT_TRNSCTN_ID  
WHERE PO.PARENT_TRNSCTN_ID = @PurchaseOrderId
AND PO.ItemCode NOT IN (SELECT DISTINCT GRN_D.ItemCode FROM SCPTnGoodReceiptNote_M GRN 
INNER JOIN SCPTnGoodReceiptNote_D GRN_D ON GRN_D.PARENT_TRNSCTN_ID = GRN.TRNSCTN_ID 
WHERE PurchaseOrderId = PO.PARENT_TRNSCTN_ID)
AND PO.ItemCode NOT IN (SELECT ItemCode FROM SCPTnFreezItem 
WHERE PurchaseOrderId=PO.PARENT_TRNSCTN_ID AND ItemCode=PO.ItemCode)

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_I]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGenerateGoodRecieptNoteNo]

AS
BEGIN
	SELECT 'GR-'+RIGHT(CAST(DATEPART(YEAR,GETDATE())AS VARCHAR(50)),2)+RIGHT('00'+CAST(DATEPART(MONTH,GETDATE()) AS VARCHAR(50)),2)+'-'+RIGHT('0000'+CAST(COUNT(TRNSCTN_ID)+1 AS VARCHAR(6)),5) AS TRNSCTN_ID
    FROM SCPTnGoodReceiptNote_M 
	WHERE MONTH(TRNSCTN_DATE) = MONTH(getdate())
    AND YEAR(TRNSCTN_DATE) = YEAR(getdate())

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_R]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Tabish>
-- Create date: <Create Date,,>
-- Description:	<[Good Receipt Detail List Report,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptGoodRecieptNote]
@GRN as varchar(50)
AS
BEGIN

--SELECT a.TRNSCTN_ID as [Goods_Receipt_No],a.TRNSCTN_DATE as [Receipt_Date],a.PurchaseOrderId as [PO_Number],
--b.SupplierLongName,c.ItemCode,d.ItemName,c.RecievedQty as [Received_Quantity],c.BonusQty as [BonusQty_Quantity],
--c.ItemRate as [ItemRatee],c.TotalAmount as[Item_Amount] ,c.SaleTax as [Item_Tax],
--a.ChallanNo as [InvoiceNumber],a.ChallanDate as [InvoiceDate],e.TRNSCTN_DATE as [PoDate],SCPStUser_M.UserName,
--CASE WHEN C.DiscountType=1 THEN c.DiscountValue ELSE (C.DiscountValue/100)*TotalAmount END AS 'DiscountValue',
--c.NetAmount as AfterDiscountAmount
--,CASE WHEN a.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus 
--FROM SCPTnPharmacyIssuance_M as a 
--INNER JOIN SCPStSupplier b on a.SupplierId = b.SupplierId
--INNER JOIN SCPTnPharmacyIssuance_D c on a.TRNSCTN_ID = c.PARENT_TRNSCTN_ID
--INNER JOIN SCPStItem_M d on c.ItemCode = d.ItemCode
--INNER JOIN SCPTnPurchaseOrder_M e on a.PurchaseOrderId = e.TRNSCTN_ID
--INNER JOIN SCPTnApproval ON SCPTnApproval.TransactionDocumentId=c.PARENT_TRNSCTN_ID
--INNER JOIN SCPStUser_M ON SCPStUser_M.UserId= SCPTnApproval.ToUSer
--WHERE a.TRNSCTN_ID =@GRN

SELECT a.TRNSCTN_ID as [Goods_Receipt_No],a.TRNSCTN_DATE as [Receipt_Date],a.PurchaseOrderId as [PO_Number],a.InvoiceNo AS INV_NO,
b.SupplierLongName,c.ItemCode,d.ItemName,c.RecievedQty as [Received_Quantity],c.BonusQty as [BonusQty_Quantity],
c.ItemRate as [ItemRatee],(c.RecievedQty*c.ItemRate) as[Item_Amount] ,c.SaleTax as [Item_Tax],
a.ChallanNo as [InvoiceNumber],a.ChallanDate as [InvoiceDate],e.TRNSCTN_DATE as [PoDate],case when SCPStUser_M.UserName is null and a.IsApproved=1 then (select UserName from SCPStUser_M where UserId=a.CreatedBy) when a.IsApproved=0 then '' else SCPStUser_M.UserName end as UserName,
CASE WHEN C.DiscountType=1 THEN c.DiscountValue ELSE (C.DiscountValue/100)*TotalAmount END AS 'DiscountValue',
(((c.RecievedQty*c.ItemRate)+c.SaleTax)-(CASE WHEN C.DiscountType=1 
THEN c.DiscountValue ELSE (C.DiscountValue/100)*TotalAmount END)) as AfterDiscountAmount,c.BatchNo
,CASE WHEN a.PrintDate is null then'Orginal' else 'Duplicate' end as PrintSatus 
FROM SCPTnGoodReceiptNote_M as a 
INNER JOIN SCPStSupplier b on a.SupplierId = b.SupplierId
INNER JOIN SCPTnGoodReceiptNote_D c on a.TRNSCTN_ID = c.PARENT_TRNSCTN_ID
Left outer JOIN SCPTnApproval ON SCPTnApproval.TransactionDocumentId=c.PARENT_TRNSCTN_ID
Left outer JOIN SCPStUser_M ON SCPStUser_M.UserId= SCPTnApproval.ToUSer
INNER JOIN SCPStItem_M d on c.ItemCode = d.ItemCode
INNER JOIN SCPTnPurchaseOrder_M e on a.PurchaseOrderId = e.TRNSCTN_ID
WHERE a.TRNSCTN_ID =@GRN

END


















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC005_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetGoodRecieptNoteForSearch]
@Trnsctn_ID as varchar(50),
@ItemTypeID as int

AS
BEGIN

	SELECT PR.TRNSCTN_ID, PR.TRNSCTN_DATE, SCPStSupplier.SupplierLongName AS SupplierShortName,SCPStWraehouse.WraehouseName, PR.PurchaseOrderId, 
PR.ChallanNo, PR.ChallanDate FROM SCPTnGoodReceiptNote_M PR 
INNER JOIN SCPStSupplier ON PR.SupplierId = SCPStSupplier.SupplierId AND SCPStSupplier.ItemTypeId=@ItemTypeID
INNER JOIN SCPStWraehouse ON PR.WraehouseId = SCPStWraehouse.WraehouseId AND SCPStWraehouse.ItemTypeId=@ItemTypeID
 where PR.IsActive=1 AND PR.TRNSCTN_ID like '%'+@Trnsctn_ID+'%'
 ORDER BY PR.TRNSCTN_ID DESC

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC006_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPAutoGetPurchaseRequisition_M] 
@Trnsctn_ID as VARCHAR(50)

AS
BEGIN
	 SELECT TRANSCTN_ID,TRANSCTN_DT,ProcurementId,WraehouseId
     FROM  SCPTnPurchaseRequisition_M where TRANSCTN_ID=@Trnsctn_ID
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC006_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[Sp_SCPGetAutoPurchaseRequisition_D]
(
@ParentId VARCHAR(50))
AS
begin

SELECT D.TRANS_ID,D.ItemCode,m.ItemName,D.CurrentStock,D.MinLevel,d.MaxLevel,RequestedQty,
ISNULL(PD.OrderQty,0) AS OrderQty,RequestedQty-ISNULL(OrderQty,0) AS PEN_QTY
FROM SCPStItem_M m, SCPTnPurchaseRequisition_D  D
LEFT OUTER JOIN SCPTnPurchaseOrder_D PD ON PD.ItemCode = D.ItemCode AND PD.PurchaseRequisitionId =@ParentId 
WHERE D.PARENT_TRANS_ID = @ParentId and m.ItemCode=d.ItemCode

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC006_D2N]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROC [dbo].[Sp_SCPGetAutoPurchaseRequisition]
(
@item int,
@Wid int
)
AS
BEGIN

--if(@item='1')
--select d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,d.ItemTypeId,pd.TRNSCTN_ID,
--ISNULL(I.CurrentStock,0) AS CRNT,0 as OrderQty,
--isnull(ISNULL(pd.MaxLevel,0)-ISNULL(I.CurrentStock,0),0) as REQQTY,
--isnull(ISNULL(pd.MaxLevel,0)-ISNULL(I.CurrentStock,0),0) as PENQTY
--from  SCPStItem_M d
--inner join SCPStItem_D_WraehouseName as a on a.ItemCode=d.ItemCode
--LEFT OUTER JOIN SCPStParLevelAssignment_D pd on d.ItemCode=pd.ItemCode and pd.TRNSCTN_ID=(select max(TRNSCTN_ID) 
--from SCPStParLevelAssignment_D x where x.ItemCode=pd.ItemCode and WraehouseId=@Wid)
--left JOIN SCPStParLevelAssignment_M P_M ON P_M.TRNSCTN_ID = PD.PARENT_TRNSCTN_ID 
--AND GETDATE() BETWEEN P_M.FromDate AND P_M.ToDate AND P_M.IsActive = 1
--LEFT OUTER JOIN SCPTnStock_M I ON I.ItemCode = d.ItemCode  
--GROUP BY  d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,d.ItemTypeId,pd.TRNSCTN_ID,I.CurrentStock
--having ISNULL(I.CurrentStock,0)<ISNULL(pd.MaxLevel,0)  and d.ItemTypeId=@item

--if(@item='2')

--select d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,d.ItemTypeId,pd.TRNSCTN_ID,isnull((select sum(c.CurrentStock)
--as ItemBalance from SCPTnStock_M as c where ItemCode=d.ItemCode and WraehouseId=@Wid),0) AS CRNT,0 as OrderQty,
--isnull(ISNULL(pd.MaxLevel,0)-isnull((select sum(c.CurrentStock) as ItemBalance from SCPTnStock_M as c where ItemCode=d.ItemCode 
--and WraehouseId=@Wid),0),0) as REQQTY,isnull(ISNULL(pd.MaxLevel,0)-isnull((select sum(c.CurrentStock) as ItemBalance
--from SCPTnStock_M as c where ItemCode=d.ItemCode and WraehouseId=@Wid),0),0) as PENQTY from  SCPStItem_M d inner join SCPStItem_D_WraehouseName as a 
--on a.ItemCode=d.ItemCode LEFT OUTER JOIN SCPStParLevelAssignment_D pd on d.ItemCode=pd.ItemCode and pd.TRNSCTN_ID=(select max(TRNSCTN_ID) from
--SCPStParLevelAssignment_D x where x.ItemCode=pd.ItemCode and WraehouseId=@Wid) left JOIN SCPStParLevelAssignment_M P_M ON P_M.TRNSCTN_ID = PD.PARENT_TRNSCTN_ID 
--AND GETDATE() BETWEEN P_M.FromDate AND P_M.ToDate AND P_M.IsActive = 1
--GROUP BY  d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,d.ItemTypeId,pd.TRNSCTN_ID
--having isnull((select sum(c.CurrentStock) as ItemBalance from SCPTnStock_M as c 
--where ItemCode=d.ItemCode and WraehouseId=@Wid),0)<ISNULL(pd.MaxLevel,0) and 
--d.ItemTypeId=@item



--SELECT ItemCode,ItemName,MaxLevel,MinLevel,CRNT,OrderQty,REQQTY,PENQTY FROM  
--(
--  SELECT ItemCode,ItemName,MinLevel,MaxLevel,CRNT,((MaxLevel-CRNT)-CRNT_PR) AS REQQTY,((MaxLevel-CRNT)-CRNT_PR) AS PENQTY,
--   CRNT_PR,0 AS OrderQty FROM
--  (
--	select d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,isnull((select sum(c.CurrentStock) from SCPTnStock_M AS c
--	where ItemCode=d.ItemCode and WraehouseId=@Wid),0) AS CRNT,ISNULL((SELECT SUM(PRCD.PendingQty) FROM SCPTnPurchaseRequisition_D PRCD 
--	WHERE PRCD.ItemCode=d.ItemCode),0) AS CRNT_PR from  SCPStItem_M d 
--	INNER JOIN SCPStItem_D_WraehouseName as a on a.ItemCode=d.ItemCode 
--	INNER JOIN SCPStParLevelAssignment_D pd on d.ItemCode=pd.ItemCode  
--	INNER JOIN SCPStParLevelAssignment_M P_M ON P_M.TRNSCTN_ID = PD.PARENT_TRNSCTN_ID AND GETDATE() BETWEEN P_M.FromDate AND P_M.ToDate 
--	and P_M.WraehouseId=@Wid AND P_M.IsActive = 1
--	GROUP BY  d.ItemCode,d.ItemName,pd.MaxLevel,pd.MinLevel,d.ItemTypeId,pd.TRNSCTN_ID
--	having isnull((select sum(c.CurrentStock) as ItemBalance from SCPTnStock_M as c 
--	where ItemCode=d.ItemCode and WraehouseId=@Wid),0)<ISNULL(pd.MaxLevel,0) and 
--	d.ItemTypeId=@item
--  )TMP 
--)TM WHERE REQQTY>0

 --SELECT ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CRNT,
 --((SUM(MaxLevel)-CRNT)-CRNT_PR) AS REQQTY,((SUM(MaxLevel)-CRNT)-CRNT_PR) AS PENQTY,0 AS OrderQty FROM
 -- (
	--select d.ItemCode,d.ItemName,CASE WHEN pd.ParLevelId = 14 THEN pd.NewLevel ELSE 0 END AS MinLevel,
 --   CASE WHEN pd.ParLevelId = 16 THEN pd.NewLevel ELSE 0 END AS MaxLevel,isnull(sum(c.CurrentStock),0) AS CRNT,
	--(
	--SELECT ISNULL(SUM(PendingQty),0) AS PendingQty FROM (
 --   SELECT (ISNULL(SUM(PRCD.PendingQty),0)+ISNULL((SELECT SUM(PendingQty) FROM SCPTnPurchaseOrder_D
	--INNER JOIN SCPTnPurchaseOrder_M ON SCPTnPurchaseOrder_M.TRNSCTN_ID=SCPTnPurchaseOrder_D.PurchaseOrderId 
	----INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId = SCPTnPurchaseOrder_M.SupplierId 
	--WHERE ItemCode=PRCD.ItemCode AND PurchaseRequisitionId=PRCM.TRANSCTN_ID
	----AND DATEDIFF(DAY, SCPTnPurchaseOrder_M.TRNSCTN_DATE, GETDATE())<SCPStSupplier.LeadTime 
	--AND SCPTnPurchaseOrder_M.IsActive = 1 AND SCPTnPurchaseOrder_M.WarehouseId=@Wid),0)+ISNULL((SELECT SUM(SCPTnPharmacyIssuance_D.RecievedQty) FROM SCPTnPharmacyIssuance_D 
	--INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID = SCPTnPharmacyIssuance_M.TRNSCTN_ID
	--AND ISNULL(SCPTnPharmacyIssuance_M.IsApproved,0)=0 AND ISNULL(IsReject,0)!=1 AND SCPTnPharmacyIssuance_D.ItemCode=PRCD.ItemCode AND 
	--SCPTnPharmacyIssuance_M.WraehouseId=@Wid),0)) AS PendingQty FROM SCPTnPurchaseRequisition_D PRCD
	--INNER JOIN SCPTnPurchaseRequisition_M PRCM ON PRCM.TRANSCTN_ID=PRCD.PARENT_TRANS_ID and PRCM.WraehouseId=@Wid AND PRCM.IsActive = 1
	--WHERE PRCD.ItemCode=d.ItemCode AND PRCM.IsApprove = 1 GROUP BY PRCM.TRANSCTN_ID,PRCD.ItemCode
	--)TMP) AS CRNT_PR from  SCPStItem_M d 
	--INNER JOIN SCPStItem_D_WraehouseName as a on a.ItemCode=d.ItemCode AND a.WraehouseId=@Wid
	--LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=d.ItemCode AND c.WraehouseId=a.WraehouseId
	--INNER JOIN SCPStParLevelAssignment_M P_M ON d.ItemCode=P_M.ItemCode AND P_M.WraehouseId =a.WraehouseId
	--AND P_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=P_M.ItemCode AND CC.IsActive = 1 AND WraehouseId=@Wid) 
	--INNER JOIN SCPStParLevelAssignment_D pd on P_M.TRNSCTN_ID = PD.PARENT_TRNSCTNID AND PD.ParLevelId IN (14,16) 
	--where d.IsActive=1
	--GROUP BY  d.ItemCode,d.ItemName,pd.ParLevelId,pd.NewLevel
 -- )TMP GROUP BY ItemCode,ItemName,CRNT,CRNT_PR HAVING SUM(MinLevel)!=0 AND CRNT<= SUM(MinLevel) AND ((SUM(MaxLevel)-CRNT)-CRNT_PR)>0
  
  SELECT CONVERT(varchar(10),ItemCode) as ItemCode,CONVERT(varchar(50),ItemName) as ItemName,CONVERT(varchar(10),SUM(MinLevel)) AS MinLevel,CONVERT(varchar(10),SUM(MaxLevel)) AS MaxLevel,CONVERT(varchar(10),CRNT) as CRNT,
 CONVERT(varchar(10),((SUM(MaxLevel)-CRNT)-CRNT_PR)) AS REQQTY,CONVERT(varchar(10),((SUM(MaxLevel)-CRNT)-CRNT_PR)) AS PENQTY,CONVERT(varchar(10),0) AS OrderQty FROM
  (
  select d.ItemCode,d.ItemName,CASE WHEN pd.ParLevelId = 14 THEN pd.NewLevel ELSE 0 END AS MinLevel,
    CASE WHEN pd.ParLevelId = 16 THEN pd.NewLevel ELSE 0 END AS MaxLevel,isnull(sum(c.CurrentStock),0) AS CRNT,
	(
	SELECT ISNULL(SUM(PendingQty),0) AS PendingQty FROM (
    SELECT (ISNULL(SUM(PRCD.PendingQty),0)+ISNULL((SELECT SUM(PendingQty) FROM SCPTnPurchaseOrder_D
	INNER JOIN SCPTnPurchaseOrder_M ON SCPTnPurchaseOrder_M.TRNSCTN_ID=SCPTnPurchaseOrder_D.PurchaseOrderId 
	--INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId = SCPTnPurchaseOrder_M.SupplierId 
	WHERE ItemCode=PRCD.ItemCode AND PurchaseRequisitionId=PRCM.TRANSCTN_ID
	--AND DATEDIFF(DAY, SCPTnPurchaseOrder_M.TRNSCTN_DATE, GETDATE())<SCPStSupplier.LeadTime 
	AND SCPTnPurchaseOrder_M.IsActive = 1 AND SCPTnPurchaseOrder_M.WarehouseId=@Wid),0)+ISNULL((SELECT SUM(SCPTnGoodReceiptNote_D.RecievedQty) FROM SCPTnGoodReceiptNote_D 
	INNER JOIN SCPTnGoodReceiptNote_M ON SCPTnGoodReceiptNote_D.GoodReceiptNoteId = SCPTnGoodReceiptNote_M.GoodReceiptNoteId
	AND ISNULL(SCPTnGoodReceiptNote_M.IsApproved,0)=0 AND ISNULL(IsReject,0)!=1 AND SCPTnGoodReceiptNote_D.ItemCode=PRCD.ItemCode AND 
	SCPTnGoodReceiptNote_M.WraehouseId=@Wid),0)) AS PendingQty FROM SCPTnPurchaseRequisition_D PRCD
	INNER JOIN SCPTnPurchaseRequisition_M PRCM ON PRCM.TRANSCTN_ID=PRCD.PARENT_TRANS_ID and PRCM.WraehouseId=@Wid AND PRCM.IsActive = 1
	WHERE PRCD.ItemCode=d.ItemCode AND PRCM.IsApprove = 1 GROUP BY PRCM.TRANSCTN_ID,PRCD.ItemCode
	)TMP) AS CRNT_PR from  SCPStItem_M d 
	INNER JOIN SCPStItem_D_WraehouseName as a on a.ItemCode=d.ItemCode AND a.WraehouseId=@Wid
	LEFT OUTER JOIN SCPTnStock_M c ON c.ItemCode=d.ItemCode AND c.WraehouseId=a.WraehouseId
	INNER JOIN SCPStParLevelAssignment_M P_M ON d.ItemCode=P_M.ItemCode AND P_M.WraehouseId =a.WraehouseId
	AND P_M.TRNSCTN_ID = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=P_M.ItemCode AND CC.IsActive = 1 AND WraehouseId=@Wid) 
	INNER JOIN SCPStParLevelAssignment_D pd on P_M.TRNSCTN_ID = PD.PARENT_TRNSCTNID AND PD.ParLevelId IN (14,16) 
	where d.IsActive=1
	GROUP BY  d.ItemCode,d.ItemName,pd.ParLevelId,pd.NewLevel
  )TMP GROUP BY ItemCode,ItemName,CRNT,CRNT_PR HAVING SUM(MinLevel)!=0 AND CRNT<= SUM(MinLevel) AND ((SUM(MaxLevel)-CRNT)-CRNT_PR)>0



END







GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPRC006_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetAutoPurchaseRequisitionForSearch]
@Trnsctn_ID as varchar(50),
@TypeId as int

AS
BEGIN
	SELECT CA.TRANSCTN_ID, CA.TRANSCTN_DT,SCPStProcurementNameType.ProcurementName
    FROM   SCPTnPurchaseRequisition_M CA
    inner join SCPStProcurementNameType on SCPStProcurementNameType.ProcurementNameId=ca.ProcurementId 
    where CA.TRANSCTN_ID LIKE '%'+@Trnsctn_ID+'%' AND CA.PRCRMNT_TYPE='A'
    AND CA.ProcurementId=@TypeId 
	ORDER BY CA.TRANSCTN_ID DESC


END


GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPPRS_DASHBOARD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,MOIZ_HUSSAIN>
-- Create date: <Create Date, 9/16/2019 ,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[Sp_SCPGetPurchaseRequisitionForDashboard] 

AS
BEGIN

	declare @MANUAL_DEMAND as int, @AUTO_DEMANDS as int ,
	 @ITEM_MANUAL as int, @AMOUNT_MANUAL AS INT, @ITEM_AUTO AS INT, @AMOUNT_AUTO AS INT,
	 @AUTO_PERCENTAGE AS DECIMAL, @MANUAL_PERCENATAGE AS decimal ,
	 @AUTO_PLUS_MANUAL_SUM AS INT 
	

SELECT @MANUAL_DEMAND=SUM(MANUAL_DMND)  , @AMOUNT_MANUAL =SUM(MANUAL_AMT),
@AUTO_DEMANDS = SUM(AUTO_DMND) , @AMOUNT_AUTO = SUM(AUTO_AMT) FROM
(
SELECT CASE WHEN PRCRMNT_TYPE='A' THEN COUNT(DISTINCT MM.TRANSCTN_ID) END AS AUTO_DMND,
CASE WHEN PRCRMNT_TYPE='M' THEN COUNT(DISTINCT MM.TRANSCTN_ID) END AS MANUAL_DMND,
CASE WHEN PRCRMNT_TYPE='A' THEN SUM(DD.RequestedQty*CostPrice) END AS AUTO_AMT,
CASE WHEN PRCRMNT_TYPE='M' THEN SUM(DD.RequestedQty*CostPrice) END AS MANUAL_AMT FROM SCPTnPurchaseRequisition_M MM
INNER JOIN SCPTnPurchaseRequisition_D DD ON MM.TRANSCTN_ID = DD.PARENT_TRANS_ID
LEFT OUTER JOIN SCPStRate PRIC ON PRIC.ItemCode = DD.ItemCode AND PRIC.FromDate <= TRANSCTN_DT and PRIC.ToDate >= TRANSCTN_DT
WHERE CAST(TRANSCTN_DT AS DATE) between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) AND MM.IsActive=1
GROUP BY CAST(TRANSCTN_DT AS DATE),PRCRMNT_TYPE
)TMP 

SELECT @AUTO_PERCENTAGE = (@AUTO_DEMANDS + @MANUAL_DEMAND )

SELECT FORMAT (@AUTO_DEMANDS/@AUTO_PERCENTAGE,'###%') AS AUTO_PERCENTAGE, @AUTO_DEMANDS AS ITEM_AUTO, 
		FORMAT(@AMOUNT_AUTO/@AUTO_DEMANDS,'###,###') AS AUTO_AMOUNT,
		FORMAT (@MANUAL_DEMAND/@AUTO_PERCENTAGE,'###%') AS MANUAL_PERCENTAGE,@MANUAL_DEMAND AS ITEM_MANUAL,
			FORMAT(@AMOUNT_MANUAL/@MANUAL_DEMAND,'###,###') AS MANUAL_AMOUNT

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPtntOTMdcnDtlRpt]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptPatientOT]
@PatientIp as varchar(50),
@FromDate as varchar(50),
@ToDate as varchar(50)
AS
BEGIN
	 SELECT SCPTnSale_D.SaleId,CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105) as TRANS_DT,
	 CONVERT(VARCHAR(5),SCPTnSale_M.CreatedDate,108) as TRANS_TM,SCPStItem_M.ItemName,SUM(SCPTnSale_D.Quantity) as Quantity ,SCPTnSale_D.ItemRate,
	 SUM(ROUND(Quantity*ItemRate,0)) AS Amount FROM SCPTnSale_D INNER JOIN SCPTnSale_M ON SCPTnSale_M.SaleId=SCPTnSale_D.SaleId
     INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnSale_D.ItemCode 
	 WHERE SCPTnSale_M.PatientIp=@PatientIp AND SCPTnSale_M.PatientSubCategoryId=2  and SCPTnSale_M.IsActive=1
	 AND CAST(SCPTnSale_M.TRANS_DT as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) AND CAST(CONVERT(date,@ToDate,103) as date)
	 GROUP BY SCPTnSale_D.SaleId,CONVERT(VARCHAR(10), SCPTnSale_M.TRANS_DT, 105),
	 CONVERT(VARCHAR(5),SCPTnSale_M.CreatedDate,108),SCPStItem_M.ItemName,SCPTnSale_D.ItemRate,
	 SCPTnSale_D.Amount
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPurchaseAnalysis]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPRptPurchaseAnalysis]
AS
BEGIN
	SELECT DATEDIFF(DAY,CONVERT(DATE,TRNSCTN_DATE),CONVERT(DATE,GETDATE())) as DaysDiff,SUM(NetAmount) AS AMOUNT 
    FROM SCPTnGoodReceiptNote_M where IsActive=1 and MONTH(TRNSCTN_DATE) = MONTH(getdate()) AND YEAR(TRNSCTN_DATE) = YEAR(getdate())
    GROUP BY DATEDIFF(DAY,CONVERT(DATE,TRNSCTN_DATE),CONVERT(DATE,GETDATE())) 
 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPurchaseOrderReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Tabish>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPurchaseOrderReport]
@PO as varchar(50)
AS
BEGIN
SELECT a.TRNSCTN_ID as PO , a.TRNSCTN_DATE as PODate ,a.PO_SATUS as [Status] , 
a.PurchaseRequisitionId as PR ,b.ItemCode,b.ItemRate,b.NetAmount,b.OrderQty,c.ItemName,d.SupplierShortName,
c.PackingQuantity as [UnitOfPacking],c.ItemPackingQuantity as [PackingSize],e.TRANSCTN_DT as[PR Date]
FROM SCPTnPurchaseOrder_M as a
INNER JOIN SCPTnPurchaseOrder_D b on a.TRNSCTN_ID = b.PARENT_TRNSCTN_ID
Inner Join SCPStItem_M c on b.ItemCode = c.ItemCode
INNER JOIN SCPStSupplier d on a.SupplierId=d.SupplierId
INNER JOIN SCPTnPurchaseRequisition_M e on a.PurchaseRequisitionId = e.TRANSCTN_ID
WHERE a.TRNSCTN_ID =@PO

END
















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPPurchaseRequisitionReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPPurchaseRequisitionReport]
@PR as varchar(50)
AS
BEGIN
SELECT a.TRANSCTN_ID as PurchaseReqNo,d.WraehouseName,a.TRANSCTN_DT as PRDate ,b.ItemCode,c.ItemName as ItemDesc,b.RequestedQty ,
e.UnitName
FROM SCPTnPurchaseRequisition_M as a
Inner Join SCPTnPurchaseRequisition_D  b on a.TRANSCTN_ID = b.PARENT_TRANS_ID 
Inner Join SCPStItem_M c on b.ItemCode = c.ItemCode
Inner Join SCPStWraehouse d on a.WraehouseId = d.WraehouseId
Inner Join SCPStMeasuringUnit e on c.ItemUnit=e.UnitId
WHERE a.TRANSCTN_ID =@PR


END
















GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRateChangePercentage]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   

    CREATE PROC [dbo].[Sp_SCPGetRateChangePercentage]

	AS BEGIN
   
    SELECT ISNULL(COUNT(ItemCode),0) AS RateChange FROM SCPStRate 
	WHERE CAST(CreatedDate AS DATE) 
	BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)
	AND EOMONTH(dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0)) 
	AND ((SalePrice-CostPrice)/SalePrice*100)<10

	END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnInvoice]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptSaleRefundInvoice]
@ReturnInvoiceNumber as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;
SELECT *, CASE WHEN PatinetIp = '0' THEN '' ELSE PatinetIp END AS IP,

CASE WHEN PatientTypeName = 'Corporate' THEN (SELECT 'Corp' + ' ' + COMP.CompanyName FROM SCPStCompany COMP LEFT OUTER JOIN SCPTnSaleRefund_M 
ON COMP.CompanyId = x.Comp WHERE SCPTnSaleRefund_M.TRNSCTN_ID= @ReturnInvoiceNumber) 
WHEN PatientTypeName = 'Private' AND CareOffCode=0  THEN 'Private'
WHEN PatientTypeName = 'Private' AND CareOffCode = 1 THEN (SELECT TOP 1 'C/O' + ' ' +'Employee' + ' ' + EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSaleRefund_M ON X.CareOff = EMP.EmployeeCode WHERE SCPTnSaleRefund_M.TRNSCTN_ID= @ReturnInvoiceNumber)
WHEN PatientTypeName = 'Private' AND CareOffCode = 2 THEN (SELECT TOP 1  'C/O' + ' ' +'Consultant' + ' ' + CONS.ConsultantName FROM SCPStConsultant CONS
INNER JOIN SCPTnSaleRefund_M ON  X.CareOff = CONS.ConsultantId WHERE SCPTnSaleRefund_M.TRNSCTN_ID= @ReturnInvoiceNumber)
WHEN PatientTypeName = 'Private' AND CareOffCode = 3 THEN (SELECT TOP 1 'C/O' + ' ' +'Partner' + ' ' +  PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSaleRefund_M ON  X.CareOff= PART.PartnerId WHERE SCPTnSaleRefund_M.TRNSCTN_ID= @ReturnInvoiceNumber)
 END AS CARECODE FROM (
 select distinct * from 
(
SELECT SRM.TRNSCTN_ID, SRM.PatinetIp, srm.CreatedDate as TRNSCTN_DATE, e.UserName, SRM.BatchNo,(NamePrefix+'. '+FirstName+' '+LastName) AS SCPTnInPatientNAME,b.PatientTypeName,
  RSD.ItemCode,ItemName, RSD.ItemRate, RSD.ReturnQty  AS ReturnQty,Round(RSD.ReturnQty*RSD.ItemRate,0) ReturnAmount, SCPTnInPatient.CareOffCode  AS CareOffCode, SCPTnInPatient.CompanyId as Comp,
  '0'+ SCPTnInPatient.CareOff as CareOff
FROM SCPTnSaleRefund_M SRM INNER JOIN SCPTnInPatient ON SCPTnInPatient.PatientIp = SRM.PatinetIp
INNER JOIN SCPTnSaleRefund_D RSD ON RSD.PARENT_TRNSCTN_ID = SRM.TRNSCTN_ID
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = RSD.ItemCode
INNER JOIN SCPStUser_M e on SRM.CreatedBy=e.UserId
INNER JOIN SCPStPatientType b on SCPTnInPatient.PatientTypeId = b.PatientTypeId 
WHERE SRM.SaleRefundId = '0'  AND SRM.TRNSCTN_ID =@ReturnInvoiceNumber
--GROUP BY SRM.TRNSCTN_ID, SRM.PatinetIp, srm.CreatedDate, e.UserName, SRM.BatchNo,(NamePrefix+'. '+FirstName+' '+LastName)
--,b.PatientTypeName, RSD.ItemCode, ItemName
--, rsd.ReturnAmount, SCPTnInPatient.CareOffCode,SCPTnInPatient.CompanyId, SCPTnInPatient.CareOff 
)tmpp 
UNION ALL
select distinct * from 
(
SELECT SRM.TRNSCTN_ID, SRM.PatinetIp, srm.CreatedDate as TRNSCTN_DATE, e.UserName,SRM.BatchNo,(NamePrefix+'. '+FirstName+' '+LastName) AS SCPTnInPatientNAME, b.PatientTypeName, 
RSD.ItemCode,ItemName, RSD.ItemRate, RSD.ReturnQty  AS ReturnQty, Round(RSD.ReturnQty*RSD.ItemRate,0) ReturnAmount, SM.CareOffCode AS CareOffCode, sm.CompanyId as Comp,
 SM.CareOff as CareOff
 FROM SCPTnSale_M  SM
LEFT OUTER JOIN SCPTnSaleRefund_M SRM  ON SRM.SaleRefundId = SM.TRANS_ID
INNER JOIN SCPTnSaleRefund_D RSD ON RSD.PARENT_TRNSCTN_ID = SRM.TRNSCTN_ID
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = RSD.ItemCode
INNER JOIN SCPStUser_M e on SRM.CreatedBy=e.UserId
INNER JOIN SCPStPatientType b on SM.PatientTypeId = b.PatientTypeId 
WHERE SRM.PatinetIp ='0'  AND SRM.TRNSCTN_ID = @ReturnInvoiceNumber
--GROUP BY  SRM.TRNSCTN_ID,SRM.PatinetIp, srm.CreatedDate, e.UserName, SRM.BatchNo,(NamePrefix+'. '+FirstName+' '+LastName)
--,b.PatientTypeName, RSD.ItemCode, ItemName
--, rsd.ReturnAmount,SM.CareOffCode, sm.CompanyId,   SM.CareOff
)tmpp
)X
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPReturnPhamracyReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptPhamracyReport]
@IP as varchar(50),
@RL as varchar(50)
AS
BEGIN
	
	SET NOCOUNT ON;
IF(@RL != '0')
SELECT *, 
CASE WHEN CAREOFBY = 'Consultant' THEN (SELECT TOP 1 CONS.ConsultantName FROM  SCPStConsultant CONS 
INNER JOIN SCPTnSaleRefund_M ON X.CareOff= CONS.ConsultantId WHERE SCPTnSaleRefund_M.TRNSCTN_ID = @RL )
WHEN  CAREOFBY = 'Employee' THEN (SELECT TOP 1 EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSaleRefund_M ON X.CareOff= EMP.EmployeeCode WHERE SCPTnSaleRefund_M.TRNSCTN_ID = @RL )
WHEN CAREOFBY = 'Partner' THEN (SELECT TOP 1 PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSaleRefund_M ON X.CareOff = PART.PartnerId WHERE SCPTnSaleRefund_M.TRNSCTN_ID  = @RL  )
END AS CARECODE FROM(

SELECT RM.TRNSCTN_ID, RM.TRNSCTN_DATE,PatinetIp, (SM.NamePrefix+'.'+SM.FirstName+' '+SM.LastName) as [PTName],
 PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, CONS.ConsultantName, 
CMP.CompanyName, e.UserName, RD.ItemCode, ITM.ItemName, RD.ReturnQty, RD.ReturnAmount, SD.Quantity, SD.Amount, SM.CareOff, RD.ItemRate,
 RM.BatchNo, PAYMENT.PaymentTermName,
 CASE WHEN SM.CareOffCode = 1 THEN 'Employee'
     WHEN SM.CareOffCode= 2 THEN 'Consultant'
	 WHEN SM.CareOffCode =3 THEN 'Partner'
	 end AS CAREOFBY
  FROM SCPTnSaleRefund_M RM INNER JOIN SCPTnSale_M SM ON SM.TRANS_ID = RM.SaleRefundId 
 INNER JOIN SCPStPatientType PAT_TYPE ON PAT_TYPE.PatientTypeId = SM.PatientTypeId 
INNER JOIN SCPStPatientCategory PAT_CAT ON PAT_CAT.PatientCategoryId = SM.PatientCategoryId
--INNER JOIN SCPStPatientSubCategory PAT_SBCAT ON PAT_SBCAT.PatientSubCategoryId = sm.PatientSubCategoryId
LEFT OUTER JOIN  SCPStConsultant CONS ON  CONS.ConsultantId = SM.ConsultantId
LEFT OUTER JOIN  SCPStCompany CMP ON CMP.CompanyId = SM.CompanyId
INNER JOIN SCPTnSaleRefund_D RD ON RD.PARENT_TRNSCTN_ID = RM.TRNSCTN_ID
INNER JOIN SCPStUser_M e on RM.CreatedBy=e.UserId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = RD.ItemCode
INNER JOIN SCPStPaymentTerm PAYMENT ON PAYMENT.PaymentTermId= RD.PaymentTermId
INNER JOIN SCPTnSale_D SD ON SD.PARNT_TRANS_ID = SM.TRANS_ID AND RD.ItemCode = SD.ItemCode
WHERE RM.TRNSCTN_ID = @RL
)X

IF (@IP != '0')
SELECT *, 
CASE WHEN CAREOFBY = 'Consultant' THEN (SELECT TOP 1 CONS.ConsultantName FROM  SCPStConsultant CONS 
INNER JOIN SCPTnSaleRefund_M ON X.CareOff= CONS.ConsultantId WHERE SCPTnSaleRefund_M.PatinetIp = @IP )
WHEN  CAREOFBY = 'Employee' THEN (SELECT TOP 1 EMP.EmployeeName FROM SCPStEmployee EMP
INNER JOIN SCPTnSaleRefund_M ON X.CareOff= EMP.EmployeeCode WHERE  SCPTnSaleRefund_M.PatinetIp = @IP )
WHEN CAREOFBY = 'Partner' THEN (SELECT TOP 1 PART.PartnerName FROM SCPStPartner PART
INNER JOIN SCPTnSaleRefund_M ON X.CareOff = PART.PartnerId WHERE  SCPTnSaleRefund_M.PatinetIp = @IP  )
END AS CARECODE FROM(

SELECT RM.TRNSCTN_ID, RM.TRNSCTN_DATE,PatinetIp, (PAT.NamePrefix+'.'+PAT.FirstName+' '+PAT.LastName) as [PTName],
 PAT_TYPE.PatientTypeName, PAT_CAT.PatientCategoryName, CONS.ConsultantName,
CMP.CompanyName, e.UserName, RD.ItemCode, ITM.ItemName, RD.ReturnQty, RD.ReturnAmount, RD.SaleAmount, RD.ItemPackingQuantity, PAT.CareOff,RD.ItemRate,
 RM.BatchNo, PAYMENT.PaymentTermName,
CASE WHEN PAT.CareOffCode = 1 THEN 'Employee'
     WHEN PAT.CareOffCode= 2 THEN 'Consultant'
	 WHEN PAT.CareOffCode =3 THEN 'Partner'
	 end AS CAREOFBY
 FROM SCPTnSaleRefund_M RM INNER JOIN SCPTnInPatient PAT ON RM.PatinetIp = PAT.PatientIp 
  INNER JOIN SCPStPatientType PAT_TYPE ON PAT_TYPE.PatientTypeId = PAT.PatientTypeId
INNER JOIN SCPStPatientCategory PAT_CAT ON PAT_CAT.PatientCategoryId = PAT.PatientCategoryId
LEFT OUTER JOIN  SCPStConsultant CONS ON  CONS.ConsultantId = PAT.ConsultantId
LEFT OUTER JOIN  SCPStCompany CMP ON CMP.CompanyId = PAT.CompanyId
INNER JOIN SCPTnSaleRefund_D RD ON RD.PARENT_TRNSCTN_ID = RM.TRNSCTN_ID
 INNER JOIN SCPStUser_M e on RM.CreatedBy=e.UserId
INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = RD.ItemCode
INNER JOIN SCPStPaymentTerm PAYMENT ON PAYMENT.PaymentTermId= RD.PaymentTermId
 WHERE RM.PatinetIp = @IP
 )X
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_SRC_WISE_DETAIL_SALE_POS]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptSouceWiseSaleDetail]
@FromDate AS VARCHAR(50),
@ToDate AS  VARCHAR(50)
AS
BEGIN
	
	SELECT SALE_DETAIL_RANGE.PatientCategoryName,SALE_DETAIL_RANGE.SCPTnInPatient_SUB_CATEGORY,
	ISNULL(SALE_DETAIL_LST_24HRS.Prescription,0) AS Prescription_24HRS ,ISNULL(SALE_DETAIL_LST_24HRS.Amount,0) AS Amount_24HRS , 
	ISNULL((SALE_DETAIL_LST_24HRS.Amount/SALE_DETAIL_LST_24HRS.Prescription),0) AS PER_PNT_AVG_AMT_24HRS,
	ISNULL(SALE_DETAIL_RANGE.Prescription,0)/(DATEDIFF(day,CAST(CONVERT(date,@FromDate,103) as date) , (CAST(CONVERT(date, @ToDate,103) as date ) ))) AS Prescription_RANGE ,
	ISNULL(SALE_DETAIL_RANGE.Amount,0)/(DATEDIFF(day,CAST(CONVERT(date,@FromDate,103) as date) , (CAST(CONVERT(date, @ToDate,103) as date ) ))) AS AMOUNT_RANGE , 
	ISNULL((SALE_DETAIL_RANGE.Amount/SALE_DETAIL_RANGE.Prescription),0) AS PER_PNT_AVG_AMT_RANGE
	FROM
	(
	SELECT PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,SUM(Prescription) AS Prescription,SUM(SaleAmount)-SUM(RefundAmount) AS Amount FROM
	(
	SELECT PatientCategoryName AS PatientCategoryName,PT_SUB_CT.PatientSubCategoryName AS SCPTnInPatient_SUB_CATEGORY,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
	INNER  JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientSubCategory PT_SUB_CT ON    PT_CT.PatientCategoryId=PT_SUB_CT.PatientCategoryId AND PT_SUB_CT.PatientSubCategoryId=PMM.PatientSubCategoryId
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	group by   PatientCategoryName,PT_SUB_CT.PatientSubCategoryName
	UNION ALL	
	SELECT PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(RefundAmount,0)) AS RefundAmount FROM
	(
	SELECT DISTINCT PatinetIp,PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,ItemCode,RefundAmount from
	(
	SELECT   PHM.PatinetIp, PT_CT.PatientCategoryName AS PatientCategoryName,CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 
				THEN 'OT' ELSE 'Per' END  AS SCPTnInPatient_SUB_CATEGORY,PHD.ItemCode,ReturnAmount  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSale_M PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0' 
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	)X
	)XX 
	GROUP BY PatientCategoryName,SCPTnInPatient_SUB_CATEGORY
	UNION ALL
	SELECT  PT_CT.PatientCategoryName  AS PatientCategoryName,PatientSubCategoryName AS SCPTnInPatient_Sub_Category,COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS SaleAmount,0 AS RefundAmount 
	FROM(
	SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId,PHM.PatientSubCategoryId AS SCPTnInPatient_Sub_Cat FROM SCPTnSale_M PHM 
	INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
	WHERE CAST(PHM.TRANS_DT AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date)AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
	GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId,PHM.PatientSubCategoryId
	)X
	 INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
	 INNER JOIN SCPStPatientSubCategory PT_SUB_CT ON x.SCPTnInPatient_SUB_CAT = PT_SUB_CT.PatientSubCategoryId and PT_SUB_CT.IsActive = '1'
	GROUP BY PT_CT.PatientCategoryName,PatientSubCategoryName
		)TMP GROUP BY PatientCategoryName,SCPTnInPatient_SUB_CATEGORY
	
	)SALE_DETAIL_RANGE

	LEFT OUTER JOIN 

	(SELECT PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,Prescription,Amount , (Amount/Prescription) AS PER_PNT_AVG_AMT
	FROM
	(
	SELECT PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,SUM(Prescription) AS Prescription,SUM(SaleAmount)-SUM(RefundAmount) AS Amount FROM
	(
	SELECT PatientCategoryName AS PatientCategoryName,PT_SUB_CT.PatientSubCategoryName AS SCPTnInPatient_SUB_CATEGORY,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
	INNER  JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPStPatientSubCategory PT_SUB_CT ON    PT_CT.PatientCategoryId=PT_SUB_CT.PatientCategoryId AND PT_SUB_CT.PatientSubCategoryId=PMM.PatientSubCategoryId
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE) AND PHM.IsActive=1
	group by   PatientCategoryName,PT_SUB_CT.PatientSubCategoryName
	UNION ALL	
	SELECT PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(RefundAmount,0)) AS RefundAmount FROM
	(
	SELECT DISTINCT PatinetIp,PatientCategoryName,SCPTnInPatient_SUB_CATEGORY,ItemCode,RefundAmount from
	(
	SELECT   PHM.PatinetIp, PT_CT.PatientCategoryName AS PatientCategoryName,CASE WHEN PMM.PatientTypeId=1 AND PHD.PaymentTermId=2 
				THEN 'OT' ELSE 'Per' END  AS SCPTnInPatient_SUB_CATEGORY,PHD.ItemCode,ReturnAmount  AS RefundAmount
	FROM SCPTnSaleRefund_M PHM 
	INNER JOIN SCPTnSale_M PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0' 
	INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
	INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
	WHERE CAST(PHM.TRNSCTN_DATE AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE) AND PHM.IsActive=1
	)X
	)XX 
	GROUP BY PatientCategoryName,SCPTnInPatient_SUB_CATEGORY
	UNION ALL
	SELECT  PT_CT.PatientCategoryName  AS PatientCategoryName,PatientSubCategoryName AS SCPTnInPatient_Sub_Category,COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS SaleAmount,0 AS RefundAmount 
	FROM(
	SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId,PHM.PatientSubCategoryId AS SCPTnInPatient_Sub_Cat FROM SCPTnSale_M PHM 
	INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
	WHERE CAST(PHM.TRANS_DT AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE) AND PHM.IsActive=1
	GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId,PHM.PatientSubCategoryId
	)X
	 INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
	 INNER JOIN SCPStPatientSubCategory PT_SUB_CT ON x.SCPTnInPatient_SUB_CAT = PT_SUB_CT.PatientSubCategoryId and PT_SUB_CT.IsActive = '1'
	GROUP BY PT_CT.PatientCategoryName,PatientSubCategoryName
		)TMP GROUP BY PatientCategoryName,SCPTnInPatient_SUB_CATEGORY
	
	)SALE_DETAIL_24HRS)SALE_DETAIL_LST_24HRS ON SALE_DETAIL_LST_24HRS.SCPTnInPatient_SUB_CATEGORY = SALE_DETAIL_RANGE.SCPTnInPatient_SUB_CATEGORY
	ORDER BY 1 ASC
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_SRC_WISE_SALE_POS]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptSouceWiseSale]
@FromDate AS VARCHAR(50),
@ToDate AS  VARCHAR(50)
AS
BEGIN

SELECT MAIN.PatientCategoryName AS PatientCategoryName ,ISNULL(MAIN_Date.Amount_RANGE,0) AS Sales_24Hrs, 
ISNULL(MAIN_Date.Prescription_RANGE,'0') AS Occupancy_24Hrs,ISNULL((MAIN_Date.Amount_RANGE/MAIN_Date.Prescription_RANGE),0) AS Per_Points_Avg,
ISNULL(MAIN.Prescription/(DATEDIFF(day,CAST(CONVERT(date,@FromDate,103) as date) , (CAST(CONVERT(date, @ToDate,103) as date ) ))),0) AS Occupancy,
ISNULL(MAIN.Amount/(DATEDIFF(day,CAST(CONVERT(date,@FromDate,103) as date) , (CAST(CONVERT(date, @ToDate,103) as date ) ))),0) AS Amount,
ISNULL((MAIN.Amount/MAIN.Prescription),0) AS Per_Prescription_Avg_Amount 
FROM (
SELECT PatientCategoryName,SUM(Prescription) AS Prescription,
(SUM(SaleAmount)-SUM(RefundAmount))  AS Amount FROM
(
--declare @FromDate as Date = '2019-09-02', @ToDate as Date = getdate() 
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT  PT_CT.PatientCategoryName  AS PatientCategoryName,COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS SaleAmount,0 AS RefundAmount FROM(
SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId FROM SCPTnSale_M PHM 
INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
WHERE CAST(PHM.TRANS_DT AS DATE) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
AND CAST(CONVERT(date,@ToDate,103) as date) AND PHM.IsActive=1
GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId
)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
GROUP BY PT_CT.PatientCategoryName
)TMP GROUP BY PatientCategoryName
)MAIN 

LEFT OUTER JOIN

(
SELECT PatientCategoryName AS PatientCategoryName_RANGE,SUM(Prescription) AS Prescription_RANGE,SUM(SaleAmount)-SUM(RefundAmount) AS Amount_RANGE FROM
(
--declare @FromDate as Date = '2019-09-02', @ToDate as Date = getdate() 
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
INNER JOIN SCPTnSale_M PMM ON SaleRefundId = TRANS_ID  AND PHM.PatinetIp='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE)
 AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT PatientCategoryName AS PatientCategoryName,0 AS Prescription,0 AS SaleAmount,SUM(ROUND(ReturnAmount,0))  AS RefundAmount
FROM SCPTnSaleRefund_M PHM 
INNER JOIN SCPTnInPatient PMM ON PMM.PatientIp = PHM.PatinetIp AND PHM.SaleRefundId='0'
INNER JOIN SCPStPatientCategory PT_CT ON PMM.PatientCategoryId = PT_CT.PatientCategoryId
INNER JOIN SCPTnSaleRefund_D PHD ON PHM.TRNSCTN_ID = PHD.PARENT_TRNSCTN_ID
WHERE CAST(PHM.TRNSCTN_DATE AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE)
 AND PHM.IsActive=1
GROUP BY PatientCategoryName
UNION ALL
SELECT  PT_CT.PatientCategoryName  AS PatientCategoryName,COUNT(X.Prescription) AS Prescription, SUM(X.Amount) AS SaleAmount,0 AS RefundAmount FROM(
SELECT PHM.TRANS_ID AS Prescription,SUM(ROUND(Quantity*ItemRate,0))  AS Amount, PHM.PatientCategoryId AS PatientCategoryId FROM SCPTnSale_M PHM 
INNER JOIN SCPTnSale_D PHD ON PHM.TRANS_ID = PHD.PARNT_TRANS_ID
WHERE CAST(PHM.TRANS_DT AS DATE) = CAST(DATEADD(D, -1, GETDATE()) AS DATE)
AND PHM.IsActive=1
GROUP BY PHM.TRANS_ID, PHM.PatientCategoryId
)X INNER JOIN SCPStPatientCategory PT_CT ON X.PatientCategoryId = PT_CT.PatientCategoryId
GROUP BY PT_CT.PatientCategoryName
)TMP GROUP BY PatientCategoryName
)MAIN_Date ON  MAIN.PatientCategoryName =MAIN_Date.PatientCategoryName_RANGE

END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_STCK_001]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemBatchNoStock]

	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT,
	@BatchNo AS VARCHAR(50)

AS
BEGIN
	SET NOCOUNT ON;

	SELECT TOP 1 STOCK.CurrentStock 
	FROM SCPTnStock_M STOCK
	WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = @ItemCode
		AND BatchNo = @BatchNo AND STOCK.IsActive = 1 AND STOCK.CurrentStock != 0
	ORDER BY STOCK.StockId DESC
    
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_STCK_002]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemCurrentStock]
	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;

	--SELECT TOP 1 STOCK.CurrentStock 
	--FROM SCPTnStock_M STOCK
	--WHERE STOCK.WraehouseId = @WraehouseId AND STOCK.ItemCode = @ItemCode
	--	 AND STOCK.IsActive = 1
	--ORDER BY STOCK.StockId DESC
	
    SELECT Sum(STOCK.CurrentStock) as CurrentStock FROM SCPTnStock_M STOCK
	WHERE STOCK.WraehouseId =@WraehouseId AND STOCK.ItemCode = @ItemCode 
	AND STOCK.IsActive = 1 AND STOCK.CurrentStock != 0

    
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_STCK_003]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemAllBatchNoStock]

	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;

	SELECT STOCK.BatchNo, STOCK.CurrentStock
	 FROM SCPTnStock_M STOCK
		WHERE STOCK.ItemCode = @ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.CurrentStock != 0
  
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPRP_STCK_004]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetItemAllBatchNoStockAndRate]

	@ItemCode AS VARCHAR(50),
	@WraehouseId AS INT

AS
BEGIN
	SET NOCOUNT ON;
	--SELECT BatchNo,CurrentStock,SalePrice FROM
 --(
 --   SELECT STOCK.CreatedDate,STOCK.BatchNo, STOCK.CurrentStock,max(SCPTnPharmacyIssuance_D.SalePrice) AS SalePrice
 --   FROM SCPTnStock_M STOCK left JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode=STOCK.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo=STOCK.BatchNo
	--WHERE STOCK.ItemCode = @ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.CurrentStock != 0
 --   GROUP BY STOCK.CreatedDate,STOCK.BatchNo, STOCK.CurrentStock ) TMP 

	SELECT BatchNo,CurrentStock,SalePrice FROM
    (
		SELECT STOCK.CreatedDate,STOCK.BatchNo, STOCK.CurrentStock,CASE WHEN SCPTnGoodReceiptNote_D.SalePrice IS NULL 
		THEN PRIC.SalePrice ELSE SCPTnGoodReceiptNote_D.SalePrice END AS SalePrice
		FROM SCPTnStock_M STOCK 
		left JOIN SCPTnGoodReceiptNote_D ON SCPTnGoodReceiptNote_D.ItemCode=STOCK.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo=STOCK.BatchNo
		AND SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId = (SELECT TOP 1 SCPTnGoodReceiptNote_D.GoodReceiptNoteDetailId FROM SCPTnGoodReceiptNote_D 
		WHERE SCPTnGoodReceiptNote_D.ItemCode = STOCK.ItemCode AND SCPTnGoodReceiptNote_D.BatchNo = STOCK.BatchNo)
		left JOIN SCPStRate PRIC ON PRIC.ItemCode = STOCK.ItemCode AND PRIC.FromDate <= STOCK.CreatedDate and PRIC.ToDate >= STOCK.CreatedDate
		WHERE STOCK.ItemCode = @ItemCode AND STOCK.WraehouseId = @WraehouseId AND STOCK.CurrentStock != 0
		GROUP BY STOCK.BatchNo, STOCK.CurrentStock,SCPTnGoodReceiptNote_D.SalePrice,PRIC.SalePrice,STOCK.CreatedDate  
	) TMP order by CreatedDate  
END

GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPRptGrossProfitMargin]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[Sp_SCPRptGrossProfitMargin]
@From As varchar(12),
@To As varchar(12)
AS BEGIN

SELECT MONTH(CAST('1.' + Month_Year AS DATETIME)) AS MonthNumbr,Month_Year,SUM(TP) TP,SUM(PROFIT) PROFIT FROM
(
SELECT Month_Year,0 AS TP,ROUND(CAST((SALE-COGS) AS FLOAT)*100/CAST(SALE AS FLOAT),1)  as PROFIT FROM
(
	SELECT Month_Year,SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
	(
		SELECT format(Month_Year,'MMM-yyyy')as Month_Year ,TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC,
		ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT FROM
		(
			SELECT convert(date,PD.CreatedDate) as Month_Year,CC.ItemCode,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
			ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
				ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
				INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
				WHERE RD.ItemCode = CC.ItemCode AND convert(date,RM.TRNSCTN_DATE)= convert(date,PD.CreatedDate) 
				AND RM.IsActive=1),0) AS REFUND,
				ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
				THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
				INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
				INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
				LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
				AND PRIC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
				WHERE SCPTnPharmacyIssuance_D.ItemCode = RD.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
				LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
				AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP WHERE  STOCK.CreatedDate 
				BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode) WHERE RD.ItemCode = CC.ItemCode AND 
				convert(date,RM.TRNSCTN_DATE)=convert(date,PD.CreatedDate) AND RM.IsActive=1),0) AS COGS_REFUND 
			FROM SCPStItem_M CC
			INNER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode AND CAST(PD.CreatedDate AS DATE) 
			BETWEEN   CAST(CONVERT(date,@From,103) as date)
			AND CAST(CONVERT(date,@To,103) as date)
			INNER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
			INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
			LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 				AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 				WHERE SCPTnPharmacyIssuance_D.ItemCode = CC.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
			LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
				AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
				WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
			GROUP BY convert(date,PD.CreatedDate),CC.ItemCode,CC.ItemName
		)TMP
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRD ON PRD.ItemCode = TMP.ItemCode AND convert(date,PRD.CreatedDate)=Month_Year
		LEFT OUTER JOIN SCPTnPharmacyIssuance_M PRM ON PRD.PARENT_TRNSCTN_ID = PRM.TRNSCTN_ID 
			AND PRM.IsActive=1 AND PRM.IsApproved=1
		GROUP BY format(Month_Year,'MMM-yyyy'),TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
	)TMPP GROUP BY Month_Year
)TMPPP 

UNION ALL
SELECT Month_Year,ROUND(CAST((SALE-COGS) AS FLOAT)*100/CAST(SALE AS FLOAT),2) as TP,0 AS PROFIT FROM
(
	SELECT format(Month_Year,'MMM-yyyy') as Month_Year ,SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND) COGS FROM
	(
	    SELECT  convert(date,PD.CreatedDate) as Month_Year,CC.ItemCode,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
		ISNULL(SUM(PD.Quantity*SCPStRate.TradePrice),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
			WHERE RD.ItemCode = CC.ItemCode AND convert(date,RM.TRNSCTN_DATE)=convert(date,PD.CreatedDate) AND RM.IsActive=1),0) AS REFUND,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*SCPStRate.TradePrice,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND  convert(date,RM.TRNSCTN_DATE)= convert(date,PD.CreatedDate) 
		AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		INNER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode AND CAST(PD.CreatedDate AS DATE) 
		BETWEEN   CAST(CONVERT(date,@From,103) as date)
			AND CAST(CONVERT(date,@To,103) as date)
		INNER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
		INNER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
		AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
		WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY  convert(date,PD.CreatedDate),CC.ItemCode,CC.ItemName
	)TMPP GROUP BY format(Month_Year,'MMM-yyyy')
)TMPPP
)TMPPP GROUP BY Month_Year ORDER BY MonthNumbr

END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStReasonId_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReasonId]
@ReasonId as int
AS
BEGIN
     SELECT ReasonId,DocumentType,IsActive
     FROM SCPStReasonId  WHERE ReasonId=@ReasonId 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStReasonId_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetReasonIdList]
@DocumentType AS VARCHAR(50)
AS
BEGIN
	SELECT ReasonId,ReasonId FROM SCPStReasonId WHERE DocumentType=@DocumentType AND IsActive=1
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStReasonId_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetReasonIdForSearch]
	@FORM_NM as varchar(50),
	@SEARCH as varchar(50)
AS
BEGIN

     SELECT  ReasonId, DocumentType, ReasonId, IsActive
     FROM  SCPStReasonId WHERE DocumentType=@FORM_NM and ReasonId LIKE '%'+@SEARCH+'%'
	 ORDER BY ReasonId Desc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSaleProfit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetSaleProfit]

AS BEGIN

SELECT CAST(ROUND(CAST((SALE-COGS) AS FLOAT)*100/CAST(SALE AS FLOAT),1) AS VARCHAR(50)) +' %' as profit FROM
(
SELECT SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
(
	SELECT TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC,
	ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT FROM
	(
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
		ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND 
		EOMONTH(dateadd(m, -1,GETDATE())) AND RM.IsActive=1),0) AS REFUND,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 			WHERE SCPTnPharmacyIssuance_D.ItemCode = RD.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) AND 
		EOMONTH(dateadd(m, -1,GETDATE()))  AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode AND CAST(PD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 			WHERE SCPTnPharmacyIssuance_D.ItemCode = CC.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
	)TMP
	LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRD ON PRD.ItemCode = TMP.ItemCode AND CAST(PRD.CreatedDate AS DATE) 
		BETWEEN dateadd(m, datediff (m, 0,CAST(CONVERT(date,GETDATE(),103) as date))-1, 0) 
		AND EOMONTH(dateadd(m, -1,GETDATE()))
	LEFT OUTER JOIN SCPTnPharmacyIssuance_M PRM ON PRD.PARENT_TRNSCTN_ID = PRM.TRNSCTN_ID 
		AND PRM.IsActive=1 AND PRM.IsApproved=1
	GROUP BY TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
)TMPP
)TMPPP

END


	  



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSaleProfit_Dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Sp_SCPGetSaleProfitForDashboard]

AS BEGIN

SELECT CAST(CASE WHEN SALE=0 THEN 0 ELSE ROUND(CAST((SALE-COGS) AS FLOAT)*100/CAST(SALE AS FLOAT),1) END AS VARCHAR(50)) AS PROFIT, 
 '1.2' GROSS_PROFIT_MARGIN  FROM
(
SELECT SUM(SALE)-SUM(REFUND) SALE,SUM(COGS)-SUM(COGS_REFUND)-SUM(TotalDiscountCOUNT)-SUM(FOC) COGS FROM
(
	SELECT TMP.ItemCode,TMP.ItemName,SALE,REFUND,COGS,COGS_REFUND,ISNULL(SUM(PRD.ItemRate*PRD.BonusQty),0) AS FOC,
	ISNULL(SUM(PRD.TotalAmount-PRD.AfterDiscountAmount),0) AS TotalDiscountCOUNT FROM
	(
	    SELECT CC.ItemCode,CC.ItemName,ISNULL(SUM(ROUND(PD.Quantity*PD.ItemRate,0)),0) AS SALE,
		ISNULL(SUM(PD.Quantity*(CASE WHEN PRC.ItemRate IS NULL THEN SCPStRate.CostPrice ELSE PRC.ItemRate END)),0) AS COGS,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*RD.ItemRate,0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME) AND RM.IsActive=1),0) AS REFUND,
		ISNULL((SELECT SUM(ROUND(RD.ReturnQty*(CASE WHEN PRIC.ItemRate IS NULL 
		THEN SCPStRate.CostPrice ELSE PRIC.ItemRate END),0)) FROM SCPTnSaleRefund_D RD
		INNER JOIN SCPTnSaleRefund_M RM ON RM.TRNSCTN_ID = RD.PARENT_TRNSCTN_ID
		INNER JOIN SCPTnStock_M STOCK ON STOCK.ItemCode=RD.ItemCode AND STOCK.BatchNo=RD.BatchNo and STOCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRIC ON PRIC.ItemCode = RD.ItemCode AND PRIC.BatchNo=RD.BatchNo
 			AND PRIC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 			WHERE SCPTnPharmacyIssuance_D.ItemCode = RD.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = RD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = RD.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STOCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = RD.ItemCode)
		WHERE RD.ItemCode = CC.ItemCode AND CAST(RM.TRNSCTN_DATE AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)  AND RM.IsActive=1),0) AS COGS_REFUND FROM  SCPStItem_M CC
		LEFT OUTER JOIN SCPTnSale_D PD ON CC.ItemCode = PD.ItemCode AND CAST(PD.CreatedDate AS DATE) 
	between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
		LEFT OUTER JOIN SCPTnSale_M PHM ON PHM.TRANS_ID = PD.PARNT_TRANS_ID AND PHM.IsActive=1
		LEFT OUTER JOIN SCPTnStock_M STCK ON STCK.ItemCode=PD.ItemCode AND STCK.BatchNo=PD.BatchNo and STCK.WraehouseId=3
		LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRC ON PRC.ItemCode = CC.ItemCode AND PRC.BatchNo=PD.BatchNo
 			AND PRC.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D
 			WHERE SCPTnPharmacyIssuance_D.ItemCode = CC.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = PD.BatchNo ORDER BY CreatedDate DESC)
		LEFT OUTER JOIN SCPStRate ON SCPStRate.ItemCode = CC.ItemCode  
			AND ItemRateId = (SELECT Max(ItemRateId) FROM SCPStRate CPP 
			WHERE  STCK.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = CC.ItemCode)
		GROUP BY CC.ItemCode,CC.ItemName
	)TMP
	LEFT OUTER JOIN SCPTnPharmacyIssuance_D PRD ON PRD.ItemCode = TMP.ItemCode AND CAST(PRD.CreatedDate AS DATE) 
		between CAST(CAST(GETDATE()-31 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
	LEFT OUTER JOIN SCPTnPharmacyIssuance_M PRM ON PRD.PARENT_TRNSCTN_ID = PRM.TRNSCTN_ID 
		AND PRM.IsActive=1 AND PRM.IsApproved=1
	GROUP BY TMP.ItemCode,TMP.ItemName,SALE,COGS,REFUND,COGS_REFUND
)TMPP
)TMPPP

--SELECT CONVERT (VARCHAR(50),@PROFIT) AS PROFIT, @GROSS_PROFIT_MARGIN AS GROSS_PROFIT_MARGIN
END


	  



GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserRights] 
@USERID AS int
AS
BEGIN
   SELECT FormCode,FormName,AllowAdd,AllowEdit,AllowView,AllowDelete FROM
   (
	SELECT F.FormCode,F.FormName,isnull(AllowAdd,0) as AllowAdd,isnull(AllowEdit,0) as AllowEdit,
    isnull(AllowView,0) as AllowView,isnull(AllowDelete,0) as AllowDelete FROM SCPStFormsList F
	LEFT OUTER JOIN SCPStUser_D URD ON URD.FormCode = F.FormCode AND URD.UserId = @USERID WHERE F.IsActive = 1
	UNION ALL
	SELECT F.Sp_SCPRptCODE AS FormCode,F.Sp_SCPRptNAME AS FormName,isnull(AllowAdd,0) as AllowAdd,isnull(AllowEdit,0) as AllowEdit,
    isnull(AllowView,0) as AllowView,isnull(AllowDelete,0) as AllowDelete FROM SCPStReportsList F
	LEFT OUTER JOIN SCPStUser_D URD ON URD.FormCode = F.Sp_SCPRptCODE AND URD.UserId = @USERID WHERE F.IsActive = 1
	)TMPP ORDER BY FormCode
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUser]
@UserId as int
AS
BEGIN
	select SCPStUser_M.UserName,ISNULL(SCPStUser_M.EmployeeCode,0) AS EmployeeCode,ISNULL(SCPStEmployee.EmployeeName,'') AS EMP_NM,
	ISNULL(SCPStUser_M.UserPassword,'') AS UserPassword,CASE WHEN SCPStUser_M.PasswordExpiryDate IS NULL THEN '' 
	ELSE  CONVERT(VARCHAR(10),SCPStUser_M.PasswordExpiryDate,105) END AS PasswordExpiryDate,SCPStUser_M.ADAccount,ISNULL(SCPStUser_M.EmployeeGroupId,0) AS EmployeeGroupId,
	ISNULL(SCPStUser_M.UserGroupId,0) AS UserGroupId,SCPStUser_M.Remarks,SCPStUser_M.IsLocked,IsPasswordNeverExpire,
	SCPStUser_M.IsActive from SCPStUser_M LEFT OUTER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode=SCPStUser_M.EmployeeCode 
	where UserId=@UserId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_D2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserEmployeeGroup]
@ADacc as varchar(50)
AS
BEGIN
	  select UserId,EmployeeGroupId from SCPStUser_M
	  where ADAccount=@ADacc
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserByName]
@userName as varchar(50)
AS
BEGIN
    select UserId,UserPassword,ADAccount,EmployeeGroupId,PasswordExpiryDate,IsChangePassword,IsPasswordNeverExpire,IsLocked from SCPStUser_M 
	where UserName=@userName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_L1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetUserList]
AS
BEGIN
    SELECT DISTINCT UserName as EmployeeName, UserId, ADAccount FROM SCPStUser_M
    WHERE SCPStUser_M.IsActive=1

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_L2]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserByAD]
@ADAccount AS VARCHAR(50)
AS
BEGIN
	 SELECT UserId,UserName,ADAccount,ISNULL(EmployeeGroupId,0) AS EmployeeGroupId,
     CASE WHEN UserPassword IS NULL THEN 'AD' ELSE 'LGN' END AS USR_TYPE 
     FROM SCPStUser_M WHERE ADAccount=@ADAccount AND IsActive=1 AND IsLocked=0
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_L3]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserName] 
@UserId AS INT
AS
BEGIN
	SELECT UserName FROM SCPStUser_M WHERE UserId=@UserId
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR001_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserForSearch] 
@Search as varchar(50)
AS
BEGIN
	 select SCPStUser_M.UserId,SCPStUser_M.UserName,ISNULL(SCPStEmployee.EmployeeName,'') EMP_NM,
	ISNULL(SCPStUserGroup_M.UserGroup,'') UserGroup,	SCPStUser_M.ADAccount from SCPStUser_M 
	LEFT OUTER JOIN SCPStUserGroup_M ON SCPStUserGroup_M.UserGroupId=SCPStUser_M.UserGroupId 
	LEFT OUTER JOIN SCPStEmployee ON SCPStEmployee.EmployeeCode=SCPStUser_M.EmployeeCode 
    where SCPStUser_M.IsActive=1 and SCPStUser_M.UserId like '%'+@Search+'%' OR SCPStUser_M.UserName like '%'+@Search+'%'
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR002_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserRightsByUserGroup] 
@USER_GRP_ID AS int
AS
BEGIN
	SELECT F.FormCode,F.FormName,isnull(AllowAdd,0) as AllowAdd,isnull(AllowEdit,0) as AllowEdit,
    isnull(AllowView,0) as AllowView,isnull(AllowDelete,0) as AllowDelete FROM SCPStFormsList F
	LEFT OUTER JOIN SCPStUserGroup_D URD ON URD.FormCode = F.FormCode AND URD.UserGroupId = @USER_GRP_ID WHERE F.IsActive = 1
	UNION ALL
	SELECT F.Sp_SCPRptCODE AS FormCode,F.Sp_SCPRptNAME AS FormName,isnull(AllowAdd,0) as AllowAdd,isnull(AllowEdit,0) as AllowEdit,
    isnull(AllowView,0) as AllowView,isnull(AllowDelete,0) as AllowDelete FROM SCPStReportsList F
	LEFT OUTER JOIN SCPStUserGroup_D URD ON URD.FormCode = F.Sp_SCPRptCODE AND URD.UserGroupId = @USER_GRP_ID WHERE F.IsActive = 1

	
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR002_D1]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroup]
@User_Grp_Id as int
AS
BEGIN
	select UserGroup,IsActive from SCPStUserGroup_M where UserGroupId=@User_Grp_Id
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR002_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroupList]
AS
BEGIN
	 select UserGroupId,UserGroup from SCPStUserGroup_M where IsActive=1 order by UserGroup
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCR002_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserGroupForSearch] 
@Search as varchar(50)
AS
BEGIN
	select UserGroupId,UserGroup from SCPStUserGroup_M
    where SCPStUserGroup_M.IsActive=1 and UserGroupId like '%'+@Search+'%' OR UserGroup like '%'+@Search+'%'
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormsList_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetFormReportList]
AS
BEGIN
   select FormCode,FormName from SCPStFormsList where IsActive=1 --ORDER BY FormCode ASC
   UNION ALL
   select RptCODE AS FormCode,RptNAME AS FormName from SCPStReportsList where IsActive=1 --ORDER BY FormCode ASC
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStFormsList_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetUserAccessRights]
@UserId as int,
@FormCode as varchar(50)
AS
BEGIN
	select AllowAdd,AllowEdit,AllowDelete,AllowView from SCPStUser_D where UserId=@UserId and FormCode=@FormCode
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStEmployeeGroup_D]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroup]
@GroupId as int
AS
BEGIN
      select EmployeeGroup,IsActive from SCPStEmployeeGroup where EmployeeGroupId=@GroupId
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStEmployeeGroup_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroupList]
AS
BEGIN
	 select EmployeeGroupId,EmployeeGroup from SCPStEmployeeGroup where IsActive=1 order by EmployeeGroup
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStEmployeeGroup_S]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetEmployeeGroupForSearch]
	
	@GroupName as varchar(50)
AS
BEGIN
	 SELECT EmployeeGroupId,EmployeeGroup,IsActive
     FROM SCPStEmployeeGroup WHERE EmployeeGroup LIKE '%'+@GroupName+'%' 
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStReportsList_L]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPGetReportsListForSearch]
@UserId AS INT,
@RptCode AS VARCHAR(50)
AS
BEGIN
		SELECT DISTINCT Sp_SCPRptCODE,Sp_SCPRptNAME FROM SCPStReportsList
	INNER JOIN SCPStUser_D ON SCPStUser_D.FormCode = SCPStReportsList.Sp_SCPRptCODE
	WHERE SCPStUser_D.UserId=@UserId AND RptCODE LIKE '%' +@RptCode +'%' --and AllowView=1
	AND SCPStReportsList.IsActive=1
	ORDER BY Sp_SCPRptCODE 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPShelfWiseItemList]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Sp_SCPRptShelfWiseItemList]
@WraehouseId  int,
@RackFrom as int,
@RackTo as int
AS
BEGIN
	SET NOCOUNT ON;

 
 SELECT RK.RackName, SH.ShelfName, SH_ITM.ItemCode , ITM.ItemName, SUM(CurrentStock)AS CurrentStock  FROM SCPStRack RK
  INNER JOIN SCPStShelf SH ON SH.RackId = RK.RackId
  INNER JOIN SCPStItem_D_Shelf SH_ITM ON SH_ITM.ShelfId = SH.ShelfId
  INNER JOIN SCPStItem_M ITM ON ITM.ItemCode = SH_ITM.ItemCode and ITM.IsActive=1
  INNER JOIN SCPTnStock_M STK ON SH_ITM.ItemCode = STK.ItemCode AND STK.WraehouseId=RK.WraehouseId
  WHERE RK.WraehouseId = @WraehouseId AND RackId BETWEEN  @RackFrom   AND @RackTo
  GROUP BY RK.RackName, SH.ShelfName, SH_ITM.ItemCode , ITM.ItemName
   ORDER BY RK.RackName, SH.ShelfName, ITM.ItemName
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPShowOnHoldItems]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROC [dbo].[Sp_SCPGetOnHoldItems]

AS BEGIN

SELECT CC.ItemCode,ItemName,CONVERT(VARCHAR(10), OnHoldDate, 105) AS OnHoldDate,UserName FROM SCPStItem_M CC
INNER JOIN SCPTnOnHoldItem HOLD ON CC.ItemCode = HOLD.ItemCode
INNER JOIN SCPStUser_M USR ON USR.UserId = HOLD.CreatedBy
WHERE CC.IsActive=1 AND CC.OnHold=1 

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockConsumptionItems]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetStockConsumptionItems]
@ConsumptionTypeId AS INT,
@WraehouseId AS INT
AS
BEGIN
IF(@WraehouseId=3)
	BEGIN
	SELECT ItemCode,ItemName,OnHold FROM	
	(
		SELECT ItemCode,ItemName AS ItemName,AvgPerDay,ISNULL(OnHold,0) AS OnHold,CASE WHEN AvgPerDay=0 AND AVG_SALE=0 
		THEN 0 WHEN AvgPerDay=0 THEN AVG_SALE*100 ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM
		(
			SELECT ItemCode,ItemName,AvgPerDay,OnHold,
			ROUND(CAST(SOLD_QTY AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()),0) AS AVG_SALE FROM
			(
				SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,OnHold,
				ISNULL(SUM(Quantity),0) AS SOLD_QTY FROM SCPStItem_M
				LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
				AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
				AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1)
				WHERE SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,OnHold
			)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY,OnHold
		)TMPP GROUP BY ItemCode,ItemName,AvgPerDay,AVG_SALE,OnHold
	)TMPPP,SCPStStockConsumptionType CT 
	WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo AND CT.ItemConsumptionIdTypeId=@ConsumptionTypeId
	GROUP BY ItemCode,ItemName,OnHold ORDER BY ItemCode
	END
	ELSE
	BEGIN
	SELECT ItemCode,ItemName,OnHold FROM	
	(
		SELECT ItemCode,ItemName AS ItemName,AvgPerDay,ISNULL(OnHold,0) AS OnHold,CASE WHEN AvgPerDay=0 AND AVG_SALE=0 
		THEN 0 WHEN AvgPerDay=0 THEN AVG_SALE*100 ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM
		(
			SELECT ItemCode,ItemName,AvgPerDay,OnHold,
			ROUND(CAST(SOLD_QTY AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()),0) AS AVG_SALE FROM
			(
				SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,OnHold,
				ISNULL(SUM(IssueQty),0) AS SOLD_QTY FROM SCPStItem_M
				LEFT OUTER JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode
				AND CAST(SCPTnPharmacyIssuance_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
				AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1)
				WHERE SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay,OnHold
			)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY,OnHold
		)TMPP GROUP BY ItemCode,ItemName,AvgPerDay,AVG_SALE,OnHold
	)TMPPP,SCPStStockConsumptionType CT 
	WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo AND CT.ItemConsumptionIdTypeId=@ConsumptionTypeId
	GROUP BY ItemCode,ItemName,OnHold ORDER BY ItemCode
	END
END



GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockConsumptionPercentage]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockConsumptionPercentage]
@WraehouseId AS INT
AS
BEGIN
	DECLARE @TOTAL_ITEM FLOAT= (SELECT COUNT(ItemCode) FROM SCPStItem_M WHERE IsActive=1)

	IF(@WraehouseId=3)
	BEGIN
	SELECT CT.ItemConsumptionIdTypeId AS ConsumptionId,CT.ItemConsumptionIdTypeName ConsumptionType,
	COUNT(ItemCode) NoOfItems,ROUND(CAST(COUNT(ItemCode) AS FLOAT)*100/@TOTAL_ITEM,1) Percentage FROM	
	(
		SELECT ItemCode,AvgPerDay,AVG_SALE,CASE WHEN AvgPerDay=0 AND AVG_SALE=0 THEN 0 
		WHEN AvgPerDay=0 THEN AVG_SALE*100 ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM
		(
			SELECT ItemCode,AvgPerDay,
			CAST(SOLD_QTY AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()) AS AVG_SALE FROM
			(
				SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(Quantity),0) AS SOLD_QTY FROM SCPStItem_M
				LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
				AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
				AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1)
				WHERE SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay
			)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY
		)TMPP GROUP BY ItemCode,AvgPerDay,AVG_SALE
	)TMPPP,SCPStStockConsumptionType CT 
	WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo
	GROUP BY CT.ItemConsumptionIdTypeId,CT.ItemConsumptionIdTypeName ORDER BY CT.ItemConsumptionIdTypeId
	END
	ELSE
	BEGIN
	SELECT CT.ItemConsumptionIdTypeId AS ConsumptionId,CT.ItemConsumptionIdTypeName ConsumptionType,
	COUNT(ItemCode) NoOfItems,ROUND(CAST(COUNT(ItemCode) AS FLOAT)*100/@TOTAL_ITEM,1) Percentage FROM	
	(
		SELECT ItemCode,AvgPerDay,AVG_SALE,CASE WHEN AvgPerDay=0 AND AVG_SALE=0 THEN 0 
		WHEN AvgPerDay=0 THEN AVG_SALE*100 ELSE ROUND(AVG_SALE*100/AvgPerDay,0) END AS DIFF FROM
		(
			SELECT ItemCode,AvgPerDay,
			CAST(SOLD_QTY AS float)/DATEDIFF(DAY,DATEADD(MONTH,-3,GETDATE()),GETDATE()) AS AVG_SALE FROM
			(
				SELECT SCPStItem_M.ItemCode AS ItemCode,ItemName,AvgPerDay,ISNULL(SUM(Quantity),0) AS SOLD_QTY FROM SCPStItem_M
				LEFT OUTER JOIN SCPTnSale_D ON SCPTnSale_D.ItemCode = SCPStItem_M.ItemCode
				AND CAST(SCPTnSale_D.CreatedDate AS DATE) BETWEEN DATEADD(MONTH,-3,GETDATE()) AND GETDATE()
				INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=@WraehouseId
				AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode 
				AND CC.WraehouseId=@WraehouseId AND CC.IsActive=1)
				WHERE SCPStItem_M.IsActive=1 
				GROUP BY SCPStItem_M.ItemCode,ItemName,AvgPerDay
			)TMP GROUP BY ItemCode,ItemName,AvgPerDay,SOLD_QTY
		)TMPP GROUP BY ItemCode,AvgPerDay,AVG_SALE
	)TMPPP,SCPStStockConsumptionType CT
	WHERE DIFF>=CT.RangeFrom AND DIFF<CT.RangeTo
	GROUP BY CT.ItemConsumptionIdTypeId,CT.ItemConsumptionIdTypeName ORDER BY CT.ItemConsumptionIdTypeId
	END
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockTakingDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptStockTakingDetail]
@paramTransectionId VARCHAR (50)
AS
BEGIN
	SELECT ItemM.ItemCode AS ItemCode,
			ItemM.ItemName AS ItemName,
			STD.BatchNo AS BatchNo,
			STD.CurrentStock AS CurrentStock,
			STD.PhysicalStock AS PhysicalStock,
			ItemM.ItemUnit AS PurchasePrice,
			(STD.PhysicalStock - STD.CurrentStock) AS Variance  
	FROM [dbo].[SCPTnStockTaking_D] AS STD
	INNER JOIN [dbo].[SCPStItem_M] AS ItemM On STD.ItemCode = STD.ItemCode
	WHERE STD.PARENT_TRNSCTN_ID = @paramTransectionId
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockTakingMaster]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPGetStockTakingMaster]
@paramTransectionId VARCHAR(50)
AS
BEGIN
		SELECT STM.TRNSCTN_ID AS TransectionId,
			   STM.CreatedDate AS CreatedOn,
			   WraehouseName.WraehouseName AS WraehouseNameName FROM [dbo].[SCPTnStockTaking_M] AS STM
		INNER JOIN [dbo].[SCPStWraehouse] AS WraehouseName ON WraehouseName.WraehouseId = STM.WraehouseId
		WHERE STM.TRNSCTN_ID = @paramTransectionId
END
GO

/****** Object:  StoredProcedure [dbo].[Sp_SCPStockValue]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Sp_SCPGetStockValue] 
@WraehouseName  int
AS
BEGIN

declare
		 @FromDate as varchar(50) = cast(Cast(getdate() - 1 as date) as datetime),
		 @ToDate as varchar(50) = cast(Cast(getdate() - 1 as date) as datetime)

	SELECT  sum(STOCK_VALUE)  FROM
	(
		SELECT 
		--SCPStItem_M.ItemCode, 
		   --SCPTnStock_M.BatchNo, 
		   --Isnull((SELECT TOP 1 ItemBalance FROM   SCPTnStock_D 
				 --  WHERE  ItemCode = SCPStItem_M.ItemCode AND WraehouseId = 10 AND BatchNo = SCPTnStock_M.BatchNo 
					--	  AND Cast(CreatedDate AS DATE) <= Cast( CONVERT(DATE, @ToDate, 103) AS   DATE) ORDER  BY CreatedDate DESC), 0)  AS   CurrentStock, 
		   --CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL THEN SCPStRate.CostPrice  ELSE SCPTnPharmacyIssuance_D.ItemRate END    AS   CostPrice, 
		   ( Isnull((SELECT TOP 1 ItemBalance FROM   SCPTnStock_D 
					 WHERE  ItemCode = SCPStItem_M.ItemCode AND WraehouseId = @WraehouseName AND BatchNo = SCPTnStock_M.BatchNo 
							AND Cast(CreatedDate AS DATE) <= Cast( 	CONVERT(DATE, @ToDate, 103) AS	DATE) 
					 ORDER  BY CreatedDate DESC), 0) * ( CASE WHEN SCPTnPharmacyIssuance_D.ItemRate  IS NULL THEN SCPStRate.CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate   END ))  AS   STOCK_VALUE 
			FROM   SCPStItem_M 
		   INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode 
		   LEFT OUTER JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = SCPTnStock_M.BatchNo AND SCPTnPharmacyIssuance_D.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D 
		   WHERE SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = SCPTnStock_M.BatchNo)
		   INNER JOIN SCPStRate ON SCPStRate.ItemCode = SCPStItem_M.ItemCode 
			WHERE  SCPStItem_M.IsActive = 1 AND WraehouseId = @WraehouseName AND ItemRateId = (SELECT Max(ItemRateId) FROM   SCPStRate CPP 
					  WHERE  SCPTnStock_M.CreatedDate BETWEEN CPP.FromDate AND CPP.ToDate AND CPP.ItemCode = SCPStItem_M.ItemCode) 
			GROUP  BY SCPStItem_M.ItemCode, SCPTnStock_M.BatchNo, SCPStRate.CostPrice, SCPTnPharmacyIssuance_D.ItemRate  
			)TMP --WHERE CurrentStock>0

END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockValue_Mean]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetStockValueMean] 
@WraehouseId  int
AS
BEGIN

	SELECT SUM(CAST(ROUND(CAST(MinLevel+MaxLevel AS FLOAT)/2,0) AS INT)*CostPrice) AS MEAN_VAL  FROM
    (
		SELECT ItemCode,ItemName,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CostPrice FROM
		(
		SELECT SCPStItem_M.ItemCode,ItemName,ISNULL(CASE WHEN ParLevelId=14 THEN NewLevel END,0) AS MinLevel,
		ISNULL(CASE WHEN ParLevelId=16 THEN NewLevel END,0) AS MaxLevel,CostPrice FROM SCPStParLevelAssignment_M
		INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode = SCPStParLevelAssignment_M.ItemCode
		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId 
		AND SCPStParLevelAssignment_M.ParLevelAssignmentId=(SELECT MAX(CRM.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CRM 
		WHERE CRM.ItemCode=SCPStItem_M.ItemCode AND WraehouseId=@WraehouseId)
		INNER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode
		AND SCPStRate.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
		WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=SCPStItem_M.ItemCode)
		WHERE SCPStParLevelAssignment_M.WraehouseId=@WraehouseId and SCPStItem_M.IsActive=1
		)TMP#0 GROUP BY ItemCode,ItemName,CostPrice 
    )TMP#1
	 
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPStockValueAllWraehouseNames]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[Sp_SCPGetStockValueAllWraehouseNames]

AS BEGIN

SELECT SUM(CASE WHEN WraehouseId=3 THEN STOCK_VALUE ELSE 0 END) AS POS_Value,
SUM(CASE WHEN WraehouseId=10 THEN STOCK_VALUE ELSE 0 END) AS MSS_Value,
'+'+CAST(SUM(CASE WHEN WraehouseId=3 THEN CAST(ROUND(STOCK_VALUE*100/MEAN_VAL,0) AS INT)
ELSE 0 END)-100 AS VARCHAR(50))+' %' AS POS,CAST(SUM(CASE WHEN WraehouseId=10 
THEN CAST(ROUND(STOCK_VALUE*100/MEAN_VAL,0) AS INT) ELSE 0 END)-100 AS VARCHAR(50))+' %' AS MSS FROM
(
	SELECT WraehouseId,SUM(CAST(ROUND(CAST(MinLevel+MaxLevel AS FLOAT)/2,0) AS INT)*CostPrice) AS MEAN_VAL,
	SUM(STOCK_VALUE) STOCK_VALUE  FROM
    (
		SELECT WraehouseId,ItemCode,ItemName,STOCK_VALUE,SUM(MinLevel) AS MinLevel,SUM(MaxLevel) AS MaxLevel,CostPrice FROM
		(
			SELECT SCPStItem_D_WraehouseName.WraehouseId,SCPStItem_M.ItemCode,ItemName,SUM(INV.CurrentStock*(CASE WHEN SCPTnPharmacyIssuance_D.ItemRate IS NULL 
			THEN RATE.CostPrice ELSE SCPTnPharmacyIssuance_D.ItemRate END)) AS STOCK_VALUE,
			ISNULL(CASE WHEN ParLevelId=14 THEN NewLevel END,0) AS MinLevel,
			ISNULL(CASE WHEN ParLevelId=16 THEN NewLevel END,0) AS MaxLevel,SCPStRate.CostPrice FROM SCPStItem_M
			INNER JOIN SCPStItem_D_WraehouseName ON SCPStItem_D_WraehouseName.ItemCode = SCPStItem_M.ItemCode
			LEFT OUTER JOIN SCPTnStock_M INV ON INV.ItemCode = SCPStItem_D_WraehouseName.ItemCode AND SCPStItem_D_WraehouseName.WraehouseId = INV.WraehouseId
			INNER JOIN SCPStParLevelAssignment_M ON SCPStItem_M.ItemCode = SCPStParLevelAssignment_M.ItemCode
			INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN(14,16)
			AND SCPStParLevelAssignment_M.ParLevelAssignmentId=(SELECT MAX(CRM.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CRM 
			WHERE CRM.ItemCode=SCPStItem_M.ItemCode AND WraehouseId=SCPStItem_D_WraehouseName.WraehouseId)
			LEFT OUTER JOIN SCPStRate ON SCPStItem_M.ItemCode = SCPStRate.ItemCode 
			           AND SCPStRate.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
			WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=SCPStItem_M.ItemCode)
			LEFT OUTER JOIN SCPStRate RATE ON SCPStItem_M.ItemCode = RATE.ItemCode 
			           AND RATE.ItemRateId=(SELECT ISNULL(MAX(ItemRateId),0) FROM SCPStRate 
			WHERE INV.CreatedDate BETWEEN FromDate AND ToDate AND SCPStRate.ItemCode=SCPStItem_M.ItemCode)
			LEFT OUTER JOIN SCPTnPharmacyIssuance_D ON SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo=INV.BatchNo 
			AND SCPTnPharmacyIssuance_D.TRNSCTN_ID = (SELECT TOP 1 SCPTnPharmacyIssuance_D.TRNSCTN_ID FROM SCPTnPharmacyIssuance_D 
			WHERE SCPTnPharmacyIssuance_D.ItemCode = SCPStItem_M.ItemCode AND SCPTnPharmacyIssuance_D.BatchNo = INV.BatchNo ORDER BY CreatedDate DESC)
			WHERE SCPStItem_M.IsActive=1
			GROUP BY SCPStItem_D_WraehouseName.WraehouseId,SCPStItem_M.ItemCode,ItemName,ParLevelId,NewLevel,SCPStRate.CostPrice
		)TMP#0 GROUP BY WraehouseId,ItemCode,ItemName,STOCK_VALUE,CostPrice 
	 )TMP#1 GROUP BY WraehouseId
)TMP#2

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSummaryConsultantResultForDashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetConsultantSummaryResultForDashboard]
@StartDate datetime,@EndDate datetime
as
begin

if(@StartDate>@EndDate)
begin
set @EndDate=@StartDate
end

declare @countConsultant int =(select Count(*) from SCPStConsultantReferral_M where IsActive=1 and  StandardAmount>0);
declare @totalSpendDays int=(select ABS(SUBSTRING(cast(cast(convert(date,GETDATE(),103)as date) as varchar(max)),len(cast(convert(date,GETDATE(),103)as date))-2,len(cast(convert(date,cast(convert(date,GETDATE(),103)as date),103)as date))))-1);

if(@totalSpendDays=0)
begin
set @totalSpendDays=1
end;

with a as (
select crp49.ConsultantId,(crp49.StandardAmount/30)*@totalSpendDays StandardAmount
,sum(Quantity*ItemRate) Amount
--,isnull(phm2d.ReturnAmount,0) rtrn
--,count(p.ConsultantId) over (partition by p.ConsultantId) countPresc
from SCPStConsultantReferral_M crp49
left join SCPTnSale_M p 
ON crp49.ConsultantId = p.ConsultantId 
and cast(p.TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) and p.PatientCategoryId = 2
left JOIN SCPTnSale_D pd ON p.TRANS_ID = pd.PARNT_TRANS_ID
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
left join SCPTnSaleRefund_M phm2m on p.TRANS_ID=phm2m.SaleRefundId
left join SCPTnSaleRefund_D phm2d on phm2m.TRNSCTN_ID=phm2d.PARENT_TRNSCTN_ID and pd.ItemCode=phm2d.ItemCode and pd.BatchNo=phm2d.BatchNo
where crp20.IsActive=1 and crp49.StandardAmount>0
group by crp49.ConsultantId,(crp49.StandardAmount/30)*@totalSpendDays
)
select count(a.ConsultantId) ConsultantCount,round((cast(cast((count(a.ConsultantId)) as decimal(9,2)) AS FLOAT)/@countConsultant)*100,0) Percentage
,crp50.ZoneColor,crp50.ZoneName,crp50.ZoneId
 From SCPStConsultantReferralZone crp50,a
 where  crp50.IsActive=1 and cast((round(isnull(Amount,0),0)/StandardAmount)*100 as int) 
 between crp50.RangeFrom and crp50.RangeTo 
 group by crp50.ZoneColor,crp50.ZoneId,crp50.ZoneName

--declare @countConsultant int =(select Count(*) from SCPStConsultantReferral_M where IsActive=1 and  StandardAmount>0),
--@totalSpendDays int=(select ABS(SUBSTRING(cast(cast(convert(date,GETDATE(),103)as date) as varchar(max)),len(cast(convert(date,GETDATE(),103)as date))-2,len(cast(convert(date,cast(convert(date,GETDATE(),103)as date),103)as date))))-1);
--;with a as (
--select distinct crp49.ConsultantId
--,cast((sum(isnull(pd.Amount,0))/((StandardAmount/30)*@totalSpendDays))*100 as int) ActualAmount
--from SCPStConsultantReferral_M crp49
--left join SCPTnSale_M p 
--ON crp49.ConsultantId = p.ConsultantId and cast(p.TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) and p.PatientCategoryId = 2
--left JOIN SCPTnSale_D pd ON p.TRANS_ID = pd.PARNT_TRANS_ID
--inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
--where crp49.StandardAmount>0
--group by crp49.ConsultantId,StandardAmount
--)
--select  count(ConsultantId) ConsultantCount,round((cast(cast((count(ActualAmount)) as decimal(9,2)) AS FLOAT)/@countConsultant)*100,0) Percentage,crp50.ZoneColor,crp50.ZoneName,crp50.ZoneId
--  From SCPStConsultantReferralZone crp50 ,a
--  where crp50.IsActive=1 and cast(ActualAmount as int) between crp50.RangeFrom and crp50.RangeTo 
--  group by crp50.ZoneColor,crp50.ZoneId,crp50.ZoneName
  end
  
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSupplierPurchaseDetail]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSupplierPurchaseDetail]
@FromDate as varchar(50),
@ToDate as varchar(50),
@SUPPLIER_ID as int
AS
BEGIN

    SELECT [SCPTnPharmacyIssuance_D].PARENT_TRNSCTN_ID,
		   SUM(SCPTnPharmacyIssuance_D.RecievedQty) AS RecievedQty,
    SUM(SCPTnPharmacyIssuance_D.NetAmount) AS NetAmount FROM SCPTnPharmacyIssuance_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPharmacyIssuance_D.ItemCode
    INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=SCPTnPharmacyIssuance_M.TRNSCTN_ID
    WHERE SCPTnPharmacyIssuance_M.SupplierId=@SUPPLIER_ID AND SCPTnPharmacyIssuance_M.IsApproved = 1
	AND cast(SCPTnPharmacyIssuance_M.TRNSCTN_DATE as date) 
	BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
	AND CAST(CONVERT(date,@ToDate,103) as date) 
	GROUP BY SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID
	
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSupplierPurchaseDetailItemWise]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSupplierPurchaseDetailItemWise]
@FromDate as varchar(50),
@ToDate as varchar(50),
@SUPPLIER_ID as int
AS
BEGIN

    SELECT SCPTnPharmacyIssuance_D.ItemCode,ItemName,SUM(SCPTnPharmacyIssuance_D.RecievedQty) AS RecievedQty,ItemRate,
    SUM(SCPTnPharmacyIssuance_D.NetAmount) AS NetAmount FROM SCPTnPharmacyIssuance_D
    INNER JOIN SCPStItem_M ON SCPStItem_M.ItemCode=SCPTnPharmacyIssuance_D.ItemCode
    INNER JOIN SCPTnPharmacyIssuance_M ON SCPTnPharmacyIssuance_D.PARENT_TRNSCTN_ID=SCPTnPharmacyIssuance_M.TRNSCTN_ID
    WHERE SCPTnPharmacyIssuance_M.SupplierId=@SUPPLIER_ID AND SCPTnPharmacyIssuance_M.IsApproved = 1 AND SCPTnPharmacyIssuance_M.IsActive=1
    AND cast(SCPTnPharmacyIssuance_M.TRNSCTN_DATE as date) BETWEEN CAST(CONVERT(date,@FromDate,103) as date) 
    AND CAST(CONVERT(date,@ToDate,103) as date) 
	GROUP BY SCPTnPharmacyIssuance_D.ItemCode,ItemName,ItemRate
	
END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSupplierPurchaseSummary]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSupplierPurchaseSummary]
@FromDate as varchar(50),
@ToDate as varchar(50),
@paramItemTypeId BIGINT
AS
BEGIN
	SELECT SCPStSupplier.SupplierLongName AS SupplierShortName,
		   SUM(SCPTnPharmacyIssuance_M.NetAmount) AS AMOUNT
	FROM SCPTnPharmacyIssuance_M
    INNER JOIN SCPStSupplier ON SCPStSupplier.SupplierId=SCPTnPharmacyIssuance_M.SupplierId 
	WHERE SCPStSupplier.ItemTypeId = @paramItemTypeId AND
		  CAST(SCPTnPharmacyIssuance_M.TRNSCTN_DATE as date) BETWEEN
		  CAST(CONVERT(date,@FromDate,103) as date) AND 
		  CAST(CONVERT(date,@ToDate,103) as date)  AND SCPTnPharmacyIssuance_M.IsApproved = 1
    GROUP BY SCPStSupplier.SupplierLongName 

END
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTenDaysConsultantReferralReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetConsultantReferralTenDays]
 @ZoneID bigint,@FromDate datetime,@ToDate datetime
AS
begin
declare @minRange int,@maxRange int,@StartDate date=cast(CONVERT(date,@fromdate ,103) as date),@EndDate date=cast(CONVERT(date,@ToDate ,103) as date);
select @minRange=RangeFrom,@maxRange=RangeTo from SCPStConsultantReferralZone where ZoneId=@ZoneID;

;with a as (


select crp49.ConsultantId,crp20.ConsultantName Name,crp49.StandardAmount/3 StandardAmount
--,isnull(Quantity*ItemRate,0) ActualAmount
,Quantity,PRICE,isnull(pd.Amount,0)-isnull(phm2d.ReturnAmount,0) Amount,isnull(phm2d.ReturnAmount,0) rtrn
,crp49.PerPrescripAmt
--,count(p.ConsultantId) over (partition by p.ConsultantId) countPresc
,(select count(ConsultantId) from SCPTnSale_M where PatientCategoryId=2 and ConsultantId=p.ConsultantId and cast(TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) ) countPresc
,Percentage,crp49.AvgSCPTnInPatients
,round((((cast(crp49.AvgSCPTnInPatients as float)/100)*Percentage))/3,0) NoOfSCPTnInPatients

from SCPStConsultantReferral_M crp49
left join SCPTnSale_M p 
ON crp49.ConsultantId = p.ConsultantId 
and cast(p.TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) and p.PatientCategoryId = 2
left JOIN SCPTnSale_D pd ON p.TRANS_ID = pd.PARNT_TRANS_ID
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
left join SCPTnSaleRefund_M phm2m on p.TRANS_ID=phm2m.SaleRefundId
left join SCPTnSaleRefund_D phm2d on phm2m.TRNSCTN_ID=phm2d.PARENT_TRNSCTN_ID and pd.ItemCode=phm2d.ItemCode and pd.BatchNo=phm2d.BatchNo
--from SCPStConsultantReferral_M crp49
--left join SCPTnSale_M SCPTnSale_M on crp49.ConsultantId=SCPTnSale_M.ConsultantId and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103)  as date) >= cast('2019-04-01'  as date) 
--and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103)  as date) <= cast('2019-04-10' as date) and SCPTnSale_M.PatientCategoryId=2 
--left join SCPTnSale_D SCPTnSale_D on SCPTnSale_M.SaleId=SCPTnSale_D.SaleId
--inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
where crp20.IsActive=1 and crp49.StandardAmount>0 

)
--select sum(rtrn) from a

select cast(row_number() over(order by Name) as varchar(max)) rn,Name
,isnull(StandardAmount,0) StandardAmount
,isnull(cast(sum(round(Quantity*ItemRate,0)) as int),0) ActualAmount
,isnull(cast(sum(round(Quantity*ItemRate,0))-StandardAmount as int),0) 'Difference'
,isnull(case  when 
cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)<0 
then '-'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)as varchar(max)),'-','')
else '+'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int) as varchar(max)),'-','')
end ,0)StandardAvgPrescription
,
case when  
round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage < 0
then 
cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
else 
case when round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage =0
then cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
else'+'+ cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
end
end ReferralPercentage
, (sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100  per
 From a
 group by ConsultantId,Name,StandardAmount ,countPresc,PerPrescripAmt,AvgSCPTnInPatients,Percentage
 having 
 cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int) >= @minRange
 and cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int) <=@maxRange
 end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTenDaysConsultantReferralReportWithReasonId]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE procedure [dbo].[Sp_SCPGetConsultantReferralWithReasonIdTenDays]
 @ZoneID bigint,@FromDate datetime,@ToDate datetime
AS
begin
declare @minRange int,@maxRange int,@StartDate date=cast(CONVERT(date,@fromdate ,103) as date),@EndDate date=cast(CONVERT(date,@ToDate ,103) as date);
select @minRange=RangeFrom,@maxRange=RangeTo from SCPStConsultantReferralZone where ZoneId=@ZoneID;

select a.id,cast(row_number() over(order by a.ConsultantId) as varchar(max)) rn,a.ConsultantId,b.ConsultantName 'Name',ZoneId,ReasonIdID,StandardAmount,ActualAmount,Diff
,StandardAvgPrescription,ReferralPercentage 
From SCPStConsultantReferralComments a inner join SCPStConsultant b on a.ConsultantId=b.ConsultantId
inner join SCPStConsultantReferralReasonId crp56 on a.ReasonIdID=crp56.id
where a.ZoneId=1 and cast(a.fromdate as date)>=cast(@StartDate as date) and cast(a.todate as date)<=cast(@EndDate as date)
union all
select 0 ID,cast(row_number() over(order by Name) as varchar(max)) rn,ConsultantId,Name,cast(@ZoneID as int) ZoneId,0 ReasonIdID
,cast(isnull(StandardAmount,0) as bigint) StandardAmount
,isnull(cast(sum(round(Quantity*ItemRate,0)) as bigint),0) ActualAmount
,isnull(cast(sum(round(Quantity*ItemRate,0))-StandardAmount as bigint),0) 'Diff'
,isnull(
case  
when 
cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)<0 
then '-'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)as varchar(max)),'-','')
else '+'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int) as varchar(max)),'-','')
end ,0)StandardAvgPrescription
,
case when  
round(cast(cast((countPresc/NoOfSCPTnInPatients)*100 as decimal(9,2)) AS FLOAT),2) < 100
then 
case when  
	round(cast((countPresc/NoOfSCPTnInPatients)*100 as decimal(9,2)),0) =0
	then 
	cast(round(cast(cast((countPresc/NoOfSCPTnInPatients)*100 as decimal(9,2)) AS FLOAT),2) as varchar(max))
	else '-'+ cast(round(cast(cast((countPresc/NoOfSCPTnInPatients)*100 as decimal(9,2)) AS FLOAT),2) as varchar(max)) 
	end
else '+'+ cast(round(cast(cast((countPresc/NoOfSCPTnInPatients)*100 as decimal(9,2)) AS FLOAT),2)as varchar(max))
end ReferralPercentage
 From (
select crp49.ConsultantId,crp20.ConsultantName Name,crp49.StandardAmount/3 StandardAmount
--,isnull(Quantity*ItemRate,0) ActualAmount
,Quantity,PRICE,isnull(pd.Amount,0)-isnull(phm2d.ReturnAmount,0) Amount,isnull(phm2d.ReturnAmount,0) rtrn
,crp49.PerPrescripAmt
--,count(p.ConsultantId) over (partition by p.ConsultantId) countPresc
,(select count(ConsultantId) from SCPTnSale_M where PatientCategoryId=2 and ConsultantId=p.ConsultantId and cast(TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) ) countPresc
,Percentage,crp49.AvgSCPTnInPatients
,round((((cast(crp49.AvgSCPTnInPatients as float)/100)*Percentage))/3,0) NoOfSCPTnInPatients

from SCPStConsultantReferral_M crp49
left join SCPTnSale_M p 
ON crp49.ConsultantId = p.ConsultantId 
and cast(p.TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) and p.PatientCategoryId = 2
left JOIN SCPTnSale_D pd ON p.TRANS_ID = pd.PARNT_TRANS_ID
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
left join SCPTnSaleRefund_M phm2m on p.TRANS_ID=phm2m.SaleRefundId
left join SCPTnSaleRefund_D phm2d on phm2m.TRNSCTN_ID=phm2d.PARENT_TRNSCTN_ID and pd.ItemCode=phm2d.ItemCode and pd.BatchNo=phm2d.BatchNo
where crp20.IsActive=1 and crp49.StandardAmount>0 
and  crp49.ConsultantId not in (select a.ConsultantId from SCPStConsultantReferralComments a where a.ConsultantId=crp49.ConsultantId and cast(a.fromdate as date)>=cast(@StartDate as date) and cast(a.todate as date)<=cast(@EndDate as date))

)a
 group by ConsultantId,Name,StandardAmount ,countPresc,PerPrescripAmt,NoOfSCPTnInPatients
 having 
 cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int) >= @minRange
 and cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int) <=@maxRange
 end

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPThirtyDaysConsultantReferralReport]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_SCPGetConsultantReferralThirtyDays]
 @ZoneID bigint,@FromDate datetime,@ToDate datetime
AS
begin
declare @minRange int,@maxRange int,@StartDate date=cast(CONVERT(date,@fromdate ,103) as date),@EndDate date=cast(CONVERT(date,@ToDate ,103) as date);
declare @totalSpendDays int=(select ABS(SUBSTRING(cast(cast(convert(date,GETDATE(),103)as date) as varchar(max)),len(cast(convert(date,GETDATE(),103)as date))-2,len(cast(convert(date,cast(convert(date,GETDATE(),103)as date),103)as date))))-1);
select @minRange=RangeFrom,@maxRange=RangeTo from SCPStConsultantReferralZone where ZoneId=@ZoneID;

;with a as (
select crp49.ConsultantId,crp20.ConsultantName Name,(crp49.StandardAmount/30)*@totalSpendDays StandardAmount
--,isnull(Quantity*ItemRate,0) ActualAmount
,Quantity,PRICE,isnull(pd.Amount,0)-isnull(phm2d.ReturnAmount,0) Amount,isnull(phm2d.ReturnAmount,0) rtrn
,crp49.PerPrescripAmt
--,count(p.ConsultantId) over (partition by p.ConsultantId) countPresc
,(select count(ConsultantId) from SCPTnSale_M where PatientCategoryId=2 and ConsultantId=p.ConsultantId and cast(TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) ) countPresc
,Percentage,crp49.AvgSCPTnInPatients
,round((((cast(crp49.AvgSCPTnInPatients as float)/100)*Percentage)),0) NoOfSCPTnInPatients
from SCPStConsultantReferral_M crp49
left join SCPTnSale_M p 
ON crp49.ConsultantId = p.ConsultantId 
and cast(p.TRANS_DT as date) BETWEEN cast(@StartDate  as date)  and cast(@EndDate as date) and p.PatientCategoryId = 2
left JOIN SCPTnSale_D pd ON p.TRANS_ID = pd.PARNT_TRANS_ID
inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
left join SCPTnSaleRefund_M phm2m on p.TRANS_ID=phm2m.SaleRefundId
left join SCPTnSaleRefund_D phm2d on phm2m.TRNSCTN_ID=phm2d.PARENT_TRNSCTN_ID and pd.ItemCode=phm2d.ItemCode and pd.BatchNo=phm2d.BatchNo
--from SCPStConsultantReferral_M crp49
--left join SCPTnSale_M SCPTnSale_M on crp49.ConsultantId=SCPTnSale_M.ConsultantId and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103)  as date) >= cast('2019-04-01'  as date) 
--and cast(CONVERT(date,SCPTnSale_M.TRANS_DT ,103)  as date) <= cast('2019-04-10' as date) and SCPTnSale_M.PatientCategoryId=2 
--left join SCPTnSale_D SCPTnSale_D on SCPTnSale_M.SaleId=SCPTnSale_D.SaleId
--inner join SCPStConsultant crp20 on crp49.ConsultantId=crp20.ConsultantId
where crp20.IsActive=1 and crp49.StandardAmount>0 

)
--select sum(rtrn) from a

select cast(row_number() over(order by Name) as varchar(max)) rn,Name
,isnull(StandardAmount,0) StandardAmount
,isnull(cast(sum(round(Quantity*ItemRate,0)) as int),0) ActualAmount
,isnull(cast(sum(round(Quantity*ItemRate,0))-StandardAmount as int),0) 'Difference'
,isnull(
case  
when 
cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)<0 
then '-'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int)as varchar(max)),'-','')
else '+'+REPLACE(cast(cast(round(((sum((round(Quantity*ItemRate,0))/(case when countPresc=0 then 1 else countPresc end))-(PerPrescripAmt))),0) as int) as varchar(max)),'-','')
end ,0)StandardAvgPrescription
,
case when  
round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage < 0
then 
cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
else 
case when round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage =0
then cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
else'+'+ cast(round((cast(countPresc as float)/AvgSCPTnInPatients)*100,2)-Percentage as varchar(max)) +'%'
end
end ReferralPercentage
, (sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100  per 
 From a
 group by ConsultantId,Name,StandardAmount ,countPresc,PerPrescripAmt,/*NoOfSCPTnInPatients,*/Percentage,AvgSCPTnInPatients
 having 
 cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int)  >= @minRange
 and cast((sum(round(isnull(Quantity*ItemRate,0),0))/StandardAmount)*100 as int)  <=@maxRange
 
 end
GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPSCPStTimeType]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  CREATE PROC [dbo].[Sp_SCPGetTimeTypeList]
  
  AS
  BEGIN
  SELECT SCPStTimeTypeId,SCPStTimeType FROM SCPStTimeType
  WHERE IsActive=1
  END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTotalDelaydPo]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalDelaydPo]
AS
BEGIN
	WITH CTE AS
(
  SELECT ISNULL(COUNT(TRNSCTN_ID),0) AS Po,DaysDiff,CASE WHEN DaysDiff>=7 AND DaysDiff<10 then '7' 
  WHEN DaysDiff>=10 AND DaysDiff<15 then '10' WHEN DaysDiff>=15 AND DaysDiff<20 then '15'
  WHEN DaysDiff>=20 AND DaysDiff<30 then '20' WHEN DaysDiff>=30 then '30' end AS LeadDays  FROM
 (
  SELECT TRNSCTN_ID,DATEDIFF(DAY,CONVERT(DATE,TRNSCTN_DATE),CONVERT(DATE,GETDATE())) as DaysDiff
  FROM SCPTnPurchaseOrder_M WHERE DATEDIFF(DAY,CONVERT(DATE,TRNSCTN_DATE),CONVERT(DATE,GETDATE()))>=7 AND 
  TRNSCTN_ID NOT IN(SELECT PurchaseOrderId FROM SCPTnPharmacyIssuance_M) and IsActive=1
 )TMP GROUP BY DaysDiff
)
SELECT SUM(Po) AS TotalPo,LeadDays from CTE
GROUP BY LeadDays
ORDER BY LeadDays
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTotalDelaydPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalDelaydPR]
AS
BEGIN
	
WITH CTE AS
(
  SELECT ISNULL(COUNT(TRANSCTN_ID),0) AS PR,DaysDiff,CASE WHEN DaysDiff>=7 AND DaysDiff<10 then '7' 
  WHEN DaysDiff>=10 AND DaysDiff<15 then '10' WHEN DaysDiff>=15 AND DaysDiff<20 then '15'
  WHEN DaysDiff>=20 AND DaysDiff<30 then '20' WHEN DaysDiff>=30 then '30' end AS LeadDays  FROM
 (
  SELECT TRANSCTN_ID,DATEDIFF(DAY,CONVERT(DATE,TRANSCTN_DT),CONVERT(DATE,GETDATE())) as DaysDiff 
  FROM SCPTnPurchaseRequisition_M WHERE DATEDIFF(DAY,CONVERT(DATE,TRANSCTN_DT),CONVERT(DATE,GETDATE()))>=7 AND 
  TRANSCTN_ID NOT IN(SELECT PurchaseRequisitionId FROM SCPTnPurchaseOrder_D) and IsActive=1
 )TMP GROUP BY DaysDiff
)
SELECT SUM(PR) AS TotalPr,LeadDays from CTE
GROUP BY LeadDays
ORDER BY LeadDays
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTotalDemand]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalDemand] 
AS
BEGIN
		  DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
		  --SELECT @REPORT_DATE
  
   				select isnull((select count(*) from SCPTnDemand_M where IsActive =1 
				and DemandType='M' and	CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) 
				AND CAST(@REPORT_DATE AS date)),0) AutoDmnd,count(*) TotalDmnd from SCPTnDemand_M where IsActive =1 and
				CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		
END


GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPTotalPR]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetTotalPR] 
AS
BEGIN
		  DECLARE @REPORT_DATE AS DATETIME= GETDATE()-1;          --For To From Date
		  DECLARE @REPORT_DAY AS INT= Datepart(dw, @REPORT_DATE); --For sunday check
		  DECLARE @DAYS_DIFF AS INT = 1;						  --variable to minus current
		  DECLARE @FLAG AS BIT = 0;								  --For loop


		  WHILE @FLAG = 0
		  BEGIN
				SET @FLAG = 1;
				IF @REPORT_DAY = 1     -- Sunday Condition
				BEGIN 
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END 
				IF EXISTS (SELECT * FROM SCPStHoliday WHERE CAST(HolidayDate AS date) = CAST(@REPORT_DATE AS date) and IsActive = 1)  --Holiday Condition
				BEGIN
					SET @FLAG = 0;
					SET @DAYS_DIFF = @DAYS_DIFF +1;
					SET @REPORT_DATE = GETDATE()-@DAYS_DIFF;
					SET @REPORT_DAY = Datepart(dw, @REPORT_DATE);
				END
		  END
		  --SELECT @REPORT_DATE
  
   				select isnull((select count(*) from SCPTnPurchaseRequisition_M where IsActive =1 
				and PRCRMNT_TYPE='M' and CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) 
				AND CAST(@REPORT_DATE AS date)),0) AutoDmnd,count(*) TotalDmnd from SCPTnPurchaseRequisition_M where IsActive =1 and
				CAST(CreatedDate AS date) BETWEEN CAST(@REPORT_DATE AS date) AND CAST(@REPORT_DATE AS date)
		
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPUpdateSCPTnInPatientReAdmit]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPUpdatePatientReAdmit] 
@PatientIpNo AS VARCHAR(50)
AS
BEGIN
	 UPDATE SCPTnInPatient SET Status=1,EditedDate=GETDATE(),EDTD_BY=1 WHERE PatientIp=@PatientIpNo
END

GO
/****** Object:  StoredProcedure [dbo].[Sp_SCPWrongEntriesStock]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetWrongEntriesStock]
@WraehouseName INT
AS
BEGIN

select 0.0 AS DEAD_STOCK

--SELECT CASE WHEN @WraehouseName=3 THEN phm ELSE mss END AS DEAD_STOCK FROM
--(
      --SELECT SUM(MSS*CostPrice) AS mss,SUM(PHM*CostPrice) AS phm from
	-- (
	 --  SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) AS PHM, ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) as MSS,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,0 AS pos_MinLevel,0 AS pos_MaxLevel,SUM(MinLevel) AS MSS_MinLevel,
		--	SUM(MaxLevel) AS MSS_MaxLevel,CostPrice FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=10
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--		AND CC.WraehouseId=10 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate!='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--		)TMP GROUP BY ItemCode,ItemName,CostPrice --HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--    )TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MinLevel,MSS_MaxLevel
		--	UNION ALL
	 --  SELECT TMPP.ItemCode,ItemName,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX,ISNULL((SELECT sum(CurrentStock) FROM SCPTnStock_M 
	 --  WHERE WraehouseId=3 AND ItemCode=TMPP.ItemCode),0) as PHM,ISNULL((SELECT sum(CurrentStock) 
	 --  FROM SCPTnStock_M WHERE WraehouseId=10 AND ItemCode=TMPP.ItemCode),0) AS MSS,CostPrice FROM
	 --   (
		--	SELECT ItemCode,ItemName,SUM(MinLevel) AS pos_MinLevel,SUM(MaxLevel) AS pos_MaxLevel,0 AS MSS_MIN,0 AS MSS_MAX,CostPrice FROM
		--	(
		--		SELECT SCPStItem_M.ItemCode,ItemName,CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 14 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MinLevel,
		--		CASE WHEN SCPStParLevelAssignment_D.ParLevelId = 16 THEN SCPStParLevelAssignment_D.NewLevel ELSE 0 END AS MaxLevel,PRIC.CostPrice FROM SCPStItem_M
		--		INNER JOIN SCPStRate PRIC ON PRIC.ItemCode = SCPStItem_M.ItemCode AND GETDATE() BETWEEN FromDate AND ToDate
		--		INNER JOIN SCPStParLevelAssignment_M ON SCPStParLevelAssignment_M.ItemCode = SCPStItem_M.ItemCode AND SCPStParLevelAssignment_M.WraehouseId=3
		--		INNER JOIN SCPStParLevelAssignment_D ON SCPStParLevelAssignment_D.ParLevelAssignmentId = SCPStParLevelAssignment_M.ParLevelAssignmentId AND SCPStParLevelAssignment_D.ParLevelId IN (14,16)
		--		AND SCPStParLevelAssignment_M.ParLevelAssignmentId = (SELECT MAX(CC.TRNSCTN_ID) FROM SCPStParLevelAssignment_M CC WHERE CC.ItemCode=SCPStParLevelAssignment_M.ItemCode  
		--	    AND CC.WraehouseId=3 AND CC.IsActive=1) WHERE SCPStParLevelAssignment_M.CreatedDate!='2019-02-15 00:00:00.000' and SCPStItem_M.IsActive=1 
		--	)TMP GROUP BY ItemCode,ItemName,CostPrice --HAVING SUM(MinLevel)=0 OR SUM(MaxLevel)=0
		--)TMPP GROUP BY TMPP.ItemCode,ItemName,CostPrice,pos_MinLevel,pos_MaxLevel,MSS_MIN,MSS_MAX
	--)TMPPP
--)TMPPPP
END

GO
/****** Object:  StoredProcedure [dbo].[SpItemDetails]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_SCPGetAllItemDetails]
AS
BEGIN
	SELECT SCPStItem_M.ItemCode,ItemName,Pneumonics,ClassName,SubClassName,CategoryName,SubCategoryName,GenericName,DosageName,
	CASE WHEN FormularyName IS NULL THEN 'NON-FORMULARY' ELSE FormularyName END AS FormularyName,
	UnitName,SignaName,STG.StrengthIdName,RouteOfAdministrationTitle,CurrentStock FROM SCPStItem_M
	INNER JOIN SCPStClassification CLS ON SCPStItem_M.ClassId = CLS.ClassId
	INNER JOIN SCPStSubClassification SBCLS ON SCPStItem_M.SubClassId = SBCLS.SubClassId 
	INNER JOIN SCPStCategory CAT ON CAT.CategoryId = SCPStItem_M.CategoryId
	INNER JOIN SCPStSubCategory SBCAT ON SCPStItem_M.SubCategoryId = SBCAT.SubCategoryId 
	INNER JOIN SCPStGeneric GEN ON SCPStItem_M.GenericId = GEN.GenericId
	INNER JOIN SCPStDosage DOS ON DOS.DosageId = SCPStItem_M.DosageFormId
	LEFT OUTER JOIN SCPStFormulary FRM ON FRM.FormularyId = SCPStItem_M.FormularyId
	INNER JOIN SCPStMeasuringUnit UNIT ON UnitId = SCPStItem_M.ItemUnit
	INNER JOIN SCPStSigna SIG ON SIG.SignaId = SCPStItem_M.SignaId
	INNER JOIN SCPStStrengthId STG ON STG.StrengthIdId = SCPStItem_M.StrengthId
	INNER JOIN SCPStRouteOfAdministration ROA ON ROA.RouteOfAdministrationId = SCPStItem_M.RouteOfAdministrationId 
	INNER JOIN SCPTnStock_M ON SCPTnStock_M.ItemCode = SCPStItem_M.ItemCode AND WraehouseId=3
	ORDER BY ItemName
END

GO
/****** Object:  StoredProcedure [dbo].[SummaryItemDiscountBySupplier]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_SCPRptSummaryItemDiscountBySupplier]
@paramItemTypeId INT,
@paramFromDate NVARCHAR(50),
@paramToDate NVARCHAR(50)
AS
BEGIN
WITH CTE_ItemDiscountBySupplier(TotalItem,
							    TotalPurchase,
							    DiscountValue,
							    NumberOfNotDiscountItem,
							    NumberOfDiscountItem
							    )
AS 
(
	SELECT  SUM(ItemPurchaseD.RecievedQty) AS TotalItem,
			SUM(ItemPurchaseD.NetAmount) AS TotalPurchase,
			SUM(CASE WHEN DiscountType=1 THEN (DiscountValue) ELSE ((DiscountValue/100)*TotalAmount) END) DiscountValue ,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue =0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfNotDiscountItem,
			SUM(CASE WHEN ItemPurchaseD.DiscountValue !=0 THEN ItemPurchaseD.RecievedQty END) AS NumberOfDiscountItem
	FROM  [dbo].[SCPStSupplier] AS Supplier 
	INNER JOIN [dbo].[SCPTnPharmacyIssuance_M] AS ItemPurchaseM ON ItemPurchaseM.SupplierId = Supplier.SupplierId
	INNER JOIN [dbo].[SCPTnPharmacyIssuance_D] AS ItemPurchaseD ON ItemPurchaseM.TRNSCTN_ID = ItemPurchaseD.PARENT_TRNSCTN_ID
		--INNER JOIN [dbo].[SCPStItem_M] AS ItemManufacture ON ItemPurchaseD.ItemCode = ItemManufacture.ItemCode
	WHERE Supplier.ItemTypeId = @paramItemTypeId AND
		  CAST(ItemPurchaseM.CreatedDate as date) BETWEEN 
		  CAST(CONVERT(date,@paramFromDate,103) as date) AND
		  CAST(CONVERT(date,@paramToDate,103) as date)  
)
SELECT
	   TotalPurchase,
	   DiscountValue,
	   CONVERT(VARCHAR,ISNULL((Cast(DiscountValue as float)/TotalPurchase)*100 ,0))	 AS PercentageOfDiscountValue
FROM CTE_ItemDiscountBySupplier

END


GO
/****** Object:  StoredProcedure [dbo].[Total_Sales_POS_DASHBOARD]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROC [dbo].[Sp_SCPGetTotalSaleForDashboard] 

  AS BEGIN
  
  DECLARE @LAST_60_DAYS_AVG_SALE AS INT, @LAST_COM_DAY_24_HOURS AS INT, @TARGET_Setup  AS INT
  	set @TARGET_Setup = (SELECT CAST(StandardFeildValue AS INT) FROM SCPStStandardValue WHERE StandardFeildId=6);
	Set @LAST_60_DAYS_AVG_SALE = (SELECT ISNULL(Round((SUM(Round(PRICE*Quantity,0)) 
		-(
		 Select SUM(Round(aa.ReturnAmount,0)) as LAST_60_DAYS_AVG_SALE from SCPTnSaleRefund_D aa 
		 inner join SCPTnSaleRefund_M bb on aa.PARENT_TRNSCTN_ID = bb.TRNSCTN_ID 
		 where cast (aa.CreatedDate as date)  between CAST(GETDATE()-61 AS DATE) and CAST(GETDATE()-1 AS DATE))),0),0)  
		 FROM SCPTnSale_D a inner join SCPTnSale_M b on a.PARNT_TRANS_ID = b.TRANS_ID   
		 WHERE cast (a.CreatedDate as date)  between CAST(GETDATE()-61 AS DATE) and CAST(GETDATE()-1 AS DATE))

	set @LAST_COM_DAY_24_HOURS = (Select  (SELECT a.LAST_COM_DAY_24_HOURS as Lasthour 
		 from (
				SELECT ISNULL(round(SUM(Round(a.PRICE*a.Quantity,0)) 
				-
				(
				 Select SUM(Round(aa.ReturnAmount,0))  
				 from SCPTnSaleRefund_D aa inner join SCPTnSaleRefund_M bb 
				 on aa.PARENT_TRNSCTN_ID = bb.TRNSCTN_ID 
				 where cast (aa.CreatedDate as date)  =  CAST(GETDATE()-1 AS DATE)
				)  ,0),0) as LAST_COM_DAY_24_HOURS
				
				FROM SCPTnSale_D a inner join SCPTnSale_M b on a.PARNT_TRANS_ID = b.TRANS_ID
				where  cast (a.CreatedDate  as Date) =  CAST(GETDATE()-1 AS DATE)) as a)); 
 
 
	 SELECT @LAST_60_DAYS_AVG_SALE/60 AS Last60DaysPerDaySale,
	 @LAST_COM_DAY_24_HOURS AS LastDaySale,@TARGET_Setup AS TargetSale


  END
GO
/****** Object:  StoredProcedure [dbo].[Vendor_Distribution_Dashboard]    Script Date: 1/24/2020 1:30:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[Sp_SCPGetVendorDistributionForDashboard] 

AS
BEGIN
	declare @vendor_name as varchar(25), @VNDR_TTL_Amount_MNTH as Money , @VNDR_PERCENTAGE_CALC AS VARCHAR(10)


	Select @VNDR_TTL_Amount_MNTH = sum(vendor_details.AMOUNT) from

	(Select  b.SupplierId as Vendor_ID,sum(a.NetAmount ) as AMOUNT, c.SupplierLongName
	from SCPTnPharmacyIssuance_D a
	inner join SCPTnPharmacyIssuance_M b on a.PARENT_TRNSCTN_ID = b.TRNSCTN_ID
	inner join SCPStSupplier c on b.SupplierId = c.SupplierId
	where a.CreatedDate >= getdate()-31--between CAST(CAST(GETDATE()-62 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
	and b.IsActive = 1 
	Group by b.SupplierId ,c.SupplierLongName
	) vendor_details

	IF(@VNDR_TTL_Amount_MNTH > 0) 
	 
	BEGIN
	--set @VNDR_TTL_Amount_MNTH = 1000000
	PRINT @VNDR_TTL_Amount_MNTH; 
	 	 SELECT AMOUNT, VENDOR_NAME, PERCENTAGE as PERCENTAGE FROM
	 (SELECT Vendor_ID,AMOUNT,VENDOR_NAME,AMOUNT/@VNDR_TTL_Amount_MNTH *100 AS PERCENTAGE FROM(
	Select  b.SupplierId as Vendor_ID,sum(a.NetAmount ) as AMOUNT, c.SupplierLongName AS VENDOR_NAME 
	from SCPTnPharmacyIssuance_D a
	inner join SCPTnPharmacyIssuance_M b on a.PARENT_TRNSCTN_ID = b.TRNSCTN_ID
	inner join SCPStSupplier c on b.SupplierId = c.SupplierId
	where a.CreatedDate between CAST(CAST(GETDATE()-62 AS DATE) AS DATETIME) and CAST(CAST(GETDATE()-1 AS DATE) AS DATETIME)
	and b.IsActive = 1 	
	Group by b.SupplierId ,c.SupplierLongName)  VENDOR_DETAILS
	) MAIN_DATA 
	WHERE MAIN_DATA.PERCENTAGE >= 30
	

	
	
	END

END

GO
