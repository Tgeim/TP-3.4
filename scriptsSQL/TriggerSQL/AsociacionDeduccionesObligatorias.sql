CREATE TRIGGER dbo.TR_AsignarDeduccionesObligatorias
ON dbo.Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO dbo.DeduccionEmpleado (
            idEmpleado,
            idTipoDeduccion,
            fechaAsociacion,
            monto
        )
        SELECT
            i.id,
            td.id,
            CAST(GETDATE() AS DATE),
            td.valor
        FROM inserted i
        CROSS JOIN dbo.TipoDeduccion td
        WHERE td.obligatorio = 1;
    END TRY
    BEGIN CATCH
        
        THROW;
    END CATCH
END;
GO
