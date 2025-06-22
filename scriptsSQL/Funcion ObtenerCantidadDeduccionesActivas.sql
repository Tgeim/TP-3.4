--Función escalar que, dado un idEmpleado, devuelva el número de deducciones activas usando la vista.
CREATE FUNCTION dbo.FN_ObtenerCantidadDeduccionesActivas
(
    @inIdEmpleado INT
)
RETURNS INT
AS
BEGIN
    DECLARE @resultado INT;

    SELECT @resultado = totalDeduccionesActivas
    FROM dbo.vw_ResumenEmpleado
    WHERE idEmpleado = @inIdEmpleado;

    RETURN ISNULL(@resultado, 0);
END;
