
/*
Nombre: dbo.SP_ConsultarDeduccionesEmpleado
Descripción: Devuelve las deducciones asociadas a un empleado, activas e inactivas.
Propósito: Permitir a la aplicación mostrar el historial de deducciones por empleado.
*/

CREATE PROCEDURE dbo.SP_ConsultarDeduccionesEmpleado
    @inIdEmpleado INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DE.id,
        DE.idEmpleado,
        DE.idTipoDeduccion,
        TD.nombre AS nombreDeduccion,
        TD.porcentual,
        TD.obligatorio,
        DE.fechaAsociacion,
        DE.fechaDesasociacion
    FROM dbo.DeduccionEmpleado DE
    INNER JOIN dbo.TipoDeduccion TD ON DE.idTipoDeduccion = TD.id
    WHERE DE.idEmpleado = @inIdEmpleado
    ORDER BY DE.fechaAsociacion DESC;
END;
