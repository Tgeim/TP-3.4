
-- Tabla TipoDocumento
CREATE TABLE dbo.TipoDocumento (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Tabla Departamento
CREATE TABLE dbo.Departamento (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- Tabla Puesto
CREATE TABLE dbo.Puesto (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    salarioPorHora FLOAT NOT NULL
);

-- Tabla Empleado
CREATE TABLE dbo.Empleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    valorDocumento VARCHAR(30) NOT NULL UNIQUE,
    fechaNacimiento DATE NOT NULL,
    activo BIT NOT NULL,
    idTipoDocumento INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoDocumento(id),
    idDepartamento INT NOT NULL FOREIGN KEY REFERENCES dbo.Departamento(id),
    idPuesto INT NOT NULL FOREIGN KEY REFERENCES dbo.Puesto(id)
);

-- Tabla TipoJornada
CREATE TABLE dbo.TipoJornada (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    horaInicio VARCHAR(5) NOT NULL,
    horaFin VARCHAR(5) NOT NULL
);

-- Tabla JornadaAsignada
CREATE TABLE dbo.JornadaAsignada (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(id),
    fechaInicioSemana DATE NOT NULL,
    idTipoJornada INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoJornada(id),
    fechaCreacion DATETIME NOT NULL
);

-- Tabla Marca
CREATE TABLE dbo.Marca (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(id),
    fechaHora DATETIME NOT NULL,
    tipoMarca VARCHAR(10) NOT NULL CHECK (tipoMarca IN ('entrada', 'salida'))
);

-- Tabla TipoMovimiento
CREATE TABLE dbo.TipoMovimiento (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Tabla Movimiento
CREATE TABLE dbo.Movimiento (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(id),
    idTipoMovimiento INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoMovimiento(id),
    semana DATE NOT NULL,
    cantidadHoras FLOAT NOT NULL,
    monto FLOAT NOT NULL,
    creadoPorSistema BIT NOT NULL,
    fechaCreacion DATETIME NOT NULL
);

-- Tabla TipoDeduccion
CREATE TABLE dbo.TipoDeduccion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    porcentual BIT NOT NULL,
    valor FLOAT NOT NULL,
    obligatorio BIT NOT NULL
);

-- Tabla DeduccionEmpleado
CREATE TABLE dbo.DeduccionEmpleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(id),
    idTipoDeduccion INT NOT NULL FOREIGN KEY REFERENCES dbo.TipoDeduccion(id),
    fechaAsociacion DATE NOT NULL,
    fechaDesasociacion DATE NULL
);

-- Tabla PlanillaSemanal
CREATE TABLE dbo.PlanillaSemanal (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL FOREIGN KEY REFERENCES dbo.Empleado(id),
    semanaInicio DATE NOT NULL,
    semanaFin DATE NOT NULL,
    horasOrdinarias FLOAT NOT NULL,
    horasExtra FLOAT NOT NULL,
    montoBruto FLOAT NOT NULL,
    montoDeducciones FLOAT NOT NULL,
    montoNeto FLOAT NOT NULL,
    fechaCalculo DATETIME NOT NULL
);



-- Tabla Usuario
CREATE TABLE dbo.Usuario (
    id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    passwordHash VARCHAR(100) NOT NULL,
    esAdministrador BIT NOT NULL,
    idEmpleado INT NULL FOREIGN KEY REFERENCES dbo.Empleado(id)
);

-- Tabla BitacoraEvento
CREATE TABLE dbo.BitacoraEvento (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idUsuario INT NOT NULL FOREIGN KEY REFERENCES dbo.Usuario(id),
    idTipoEvento INT NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    idPostByUser INT NOT NULL,
    postInIP VARCHAR(50) NOT NULL,
    postTime DATETIME NOT NULL,
    jsonAntes NVARCHAR(MAX),
    jsonDespues NVARCHAR(MAX)
);
CREATE TABLE dbo.Feriado (
    id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha DATE NOT NULL
);
