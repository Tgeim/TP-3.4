/*
Nombre: dbo.SP_ListarMarcasPorEmpleadoYSemana
Descripción: Lista las marcas de entrada y salida de un empleado durante la semana indicada.
Propósito: Permitir la revisión detallada de asistencia del empleado.
*/
ALTER PROCEDURE [dbo].[SP_ListarMarcasPorEmpleadoYSemana]
    @inIdEmpleado INT,
    @inSemanaInicio DATE,
    @inSemanaFin DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar existencia del empleado activo
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Empleado WHERE id = @inIdEmpleado AND activo = 1
        )
        BEGIN
            SET @outResultCode = 50004; -- Empleado no encontrado
            RETURN;
        END

        -- Listar marcas dentro del rango y unir con la vista resumen
        SELECT
            M.id,
            M.fechaHora,
            M.tipoMarca,
            R.salarioPorHora,
            R.nombrePuesto,
            R.nombreCompleto
        FROM dbo.Marca M
        LEFT JOIN dbo.vw_ResumenEmpleado R ON M.idEmpleado = R.idEmpleado
        WHERE M.idEmpleado = @inIdEmpleado
          AND M.fechaHora BETWEEN @inSemanaInicio AND DATEADD(SECOND, -1, DATEADD(DAY, 1, @inSemanaFin))
        ORDER BY M.fechaHora;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
        SET @outResultCode = 50023; -- Error al consultar marcas
    END CATCH
END;
