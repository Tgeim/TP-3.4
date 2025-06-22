--Vista llamada vw_ResumenEmpleado, que muestra un resumen por empleado, incluyendo:
--Nombre del empleado
--Puesto
--Salario por hora
--Deducciones obligatorias asociadas
--Total de deducciones activas

CREATE VIEW dbo.vw_ResumenEmpleado
AS
SELECT 
    E.id AS idEmpleado,
    E.nombreCompleto,
    P.nombre AS nombrePuesto,
    P.salarioPorHora,
    COUNT(DE.id) AS totalDeduccionesActivas
FROM dbo.Empleado E
JOIN dbo.Puesto P ON E.idPuesto = P.id
LEFT JOIN dbo.DeduccionEmpleado DE 
    ON E.id = DE.idEmpleado AND DE.fechaDesasociacion IS NULL
GROUP BY E.id, E.nombreCompleto, P.nombre, P.salarioPorHora;
