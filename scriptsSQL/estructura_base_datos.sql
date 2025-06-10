-- Tabla TipoDocumento
CREATE TABLE TipoDocumento (
    idTipoDocumento INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Tabla Departamento
CREATE TABLE Departamento (
    idDepartamento INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- Tabla Puesto
CREATE TABLE Puesto (
    idPuesto INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    salarioPorHora FLOAT NOT NULL
);

-- Tabla Empleado
CREATE TABLE Empleado (
    idEmpleado INT PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    valorDocumento VARCHAR(30) NOT NULL UNIQUE,
    fechaNacimiento DATE NOT NULL,
    activo BIT NOT NULL,
    idTipoDocumento INT FOREIGN KEY REFERENCES TipoDocumento(idTipoDocumento),
    idDepartamento INT FOREIGN KEY REFERENCES Departamento(idDepartamento),
    idPuesto INT FOREIGN KEY REFERENCES Puesto(idPuesto)
);

-- Tabla TipoJornada
CREATE TABLE TipoJornada (
    idTipoJornada INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    horaInicio VARCHAR(5) NOT NULL,
    horaFin VARCHAR(5) NOT NULL
);

-- Tabla JornadaAsignada
CREATE TABLE JornadaAsignada (
    idJornadaAsignada INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    fechaInicioSemana DATE NOT NULL,
    idTipoJornada INT FOREIGN KEY REFERENCES TipoJornada(idTipoJornada),
    fechaCreacion DATETIME NOT NULL
);

-- Tabla Marca
CREATE TABLE Marca (
    idMarca INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    fechaHora DATETIME NOT NULL,
    tipoMarca VARCHAR(10) NOT NULL
);

-- Tabla TipoMovimiento
CREATE TABLE TipoMovimiento (
    idTipoMovimiento INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- Tabla Movimiento
CREATE TABLE Movimiento (
    idMovimiento INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    idTipoMovimiento INT FOREIGN KEY REFERENCES TipoMovimiento(idTipoMovimiento),
    semana DATE NOT NULL,
    cantidadHoras FLOAT NOT NULL,
    monto FLOAT NOT NULL,
    creadoPorSistema BIT NOT NULL,
    fechaCreacion DATETIME NOT NULL
);

-- Tabla TipoDeduccion
CREATE TABLE TipoDeduccion (
    idTipoDeduccion INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    porcentual BIT NOT NULL,
    valor FLOAT NOT NULL,
    obligatorio BIT NOT NULL
);

-- Tabla DeduccionEmpleado
CREATE TABLE DeduccionEmpleado (
    idDeduccionEmpleado INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    idTipoDeduccion INT FOREIGN KEY REFERENCES TipoDeduccion(idTipoDeduccion),
    fechaAsociacion DATE NOT NULL,
    fechaDesasociacion DATE
);

-- Tabla PlanillaSemanal
CREATE TABLE PlanillaSemanal (
    idPlanillaSemanal INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    semanaInicio DATE NOT NULL,
    semanaFin DATE NOT NULL,
    horasOrdinarias FLOAT NOT NULL,
    horasExtra FLOAT NOT NULL,
    montoBruto FLOAT NOT NULL,
    montoDeducciones FLOAT NOT NULL,
    montoNeto FLOAT NOT NULL,
    fechaCalculo DATETIME NOT NULL
);

-- Tabla PlanillaMensual
CREATE TABLE PlanillaMensual (
    idPlanillaMensual INT PRIMARY KEY,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado),
    mes VARCHAR(7) NOT NULL,
    montoTotal FLOAT NOT NULL,
    fechaCalculo DATETIME NOT NULL
);

-- Tabla Usuario
CREATE TABLE Usuario (
    idUsuario INT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    passwordHash VARCHAR(100) NOT NULL,
    esAdministrador BIT NOT NULL,
    idEmpleado INT FOREIGN KEY REFERENCES Empleado(idEmpleado)
);

-- Tabla BitacoraEvento
CREATE TABLE BitacoraEvento (
    idEvento INT PRIMARY KEY,
    idUsuario INT FOREIGN KEY REFERENCES Usuario(idUsuario),
    ipOrigen VARCHAR(50) NOT NULL,
    tipoEvento VARCHAR(20) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    fechaHora DATETIME NOT NULL,
    jsonAntes TEXT,
    jsonDespues TEXT
);
