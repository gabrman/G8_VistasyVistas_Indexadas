USE base_consorcio;
GO
/*
Crear una vista sobre la tabla administrador que solo muestre los campos apynom, sexo y fecha de nacimiento.
*/
CREATE VIEW VistaAdministrador
AS SELECT apeynom, sexo, fechnac
FROM administrador;
go

/*
Realizar insert de un lote de datos sobre la vista recien creada. Verificar el resultado en la tabla administrador.
*/
INSERT INTO VistaAdministrador (apeynom, sexo, fechnac) VALUES ('ROMAN GABRIEL ESTEBAN', 'M', '19981222');
INSERT INTO VistaAdministrador (apeynom, sexo, fechnac) VALUES ('GARCETTE FERNANDO', 'M', '19971018');
SELECT * FROM administrador;
SELECT * FROM VistaAdministrador;
go

/*
Realizar update sobre algunos de los registros creados y volver a verificar el resultado en la tabla.
*/
UPDATE VistaAdministrador
SET apeynom = 'ROMAN GABRIEL'
WHERE apeynom = 'ROMAN GABRIEL ESTEBAN'
go

/* 
Crear una vista que muestre los datos de las columnas de las siguientes tablas: 
(Administrador->Apeynom, consorcio->Nombre, gasto->periodo, gasto->fechaPago, tipoGasto->descripcion) .
*/
CREATE VIEW vista_adm_gasto_consorcio WITH SCHEMABINDING AS
	SELECT
		a.apeynom as nombre_admin,
		c.nombre as nombre_consorcio,
		g.idgasto as idGasto,
		g.periodo as periodo,
		g.fechapago as fecha_pago,
		tp.descripcion as tipo_gasto
	FROM 
		dbo.administrador a 
		JOIN dbo.consorcio c ON a.idadmin = c.idadmin
		JOIN dbo.gasto g ON c.idadmin = g.idconsorcio
		JOIN dbo.tipogasto tp ON g.idtipogasto = tp.idtipogasto
GO
select * from vista_adm_gasto_consorcio;

--index único agrupado
CREATE UNIQUE CLUSTERED INDEX UX_aplicacion ON vista_adm_gasto_consorcio(nombre_admin, nombre_consorcio, idGasto);

--index no agrupado
CREATE NONCLUSTERED INDEX IDX_fechapago ON vista_adm_gasto_consorcio(fecha_pago);

/*
ver estadistica de la vista indexada 
*/
DBCC SHOW_STATISTICS('dbo.vista_adm_gasto_consorcio', 'IDX_fechapago');

/*
Creamos un vista donde la consula nos devolvera datos del administrador del consorcio (idAdministrador, 
nombre_administrador, nombre_consorcio) y el monto total de los gastos realizados(gasto_total) acompañado del
numero total de gastos realizados(row_count).
Esta vista es para entender como se crea un indice. Ya que es una vista con pocos registros.
*/
CREATE VIEW vista_ejemplo_index WITH SCHEMABINDING AS
	SELECT 
		a.idadmin as idAdministrador,
		a.apeynom as nombre_administrador,
		c.nombre as nombre_consorcio,
		SUM(ISNULL(g.importe, 0)) as gasto_total,
		COUNT_BIG(*) as row_count
	FROM 
		dbo.administrador a 
		JOIN dbo.consorcio c ON a.idadmin = c.idadmin
		JOIN dbo.gasto g ON c.idconsorcio = g.idconsorcio
	GROUP BY a.idadmin, a.apeynom, c.nombre;
GO

/* Se crea un indice cluster sobre la columna idAdministrador, nombre_administrador, nombre_consorcio */
CREATE UNIQUE CLUSTERED INDEX IDX_ejemplo_id 
	ON vista_ejemplo_index(idAdministrador, nombre_administrador, nombre_consorcio);
GO 

DBCC SHOW_STATISTICS('dbo.vista_ejemplo_index', 'IDX_ejemplo_id');
GO

---------------------------
---Vistas segunda parte.---
---------------------------

/*
	Se puede agregar el indice no cluster a la vista que ya se presento.
*/
GO
CREATE VIEW vista_gastos WITH SCHEMABINDING AS
SELECT 
		c.nombre,
		tp.descripcion,
		g.importe,
		g.idgasto
FROM dbo.gasto g
	JOIN dbo.consorcio c ON g.idprovincia = c.idprovincia AND g.idlocalidad = c.idlocalidad AND g.idconsorcio = c.idconsorcio
	JOIN dbo.tipogasto tp ON g.idtipogasto = tp.idtipogasto
GO

CREATE UNIQUE CLUSTERED INDEX IDX_cluster_vista_gastos_idgasto ON vista_gastos(idgasto);
CREATE NONCLUSTERED INDEX IDX_ncluster_vista_gastos_tipogasto ON vista_gastos(descripcion);
GO

/*
	En este caso para no incluir tantos campos utilizamos como cluster en consorcio->nombre, aunque no es porque se puede crear
	un consorcio con el mismo nombre.
*/
CREATE VIEW vista_consorcios WITH SCHEMABINDING AS
SELECT 
	c.nombre AS nombreConsorcio,
	i.cant_dpto AS cantDepartamentos,
	p.descripcion AS provincia,
	l.descripcion AS localidad,
	z.descripcion AS zona
FROM dbo.consorcio c 
	JOIN dbo.zona z ON c.idzona = z.idzona 
	JOIN dbo.provincia p ON c.idprovincia = p.idprovincia
	JOIN dbo.localidad l ON c.idprovincia = l.idprovincia AND c.idlocalidad = l.idlocalidad
	JOIN dbo.inmueble i ON c.idprovincia = i.idprovincia AND c.idlocalidad = i.idlocalidad AND c.idconsorcio = i.idconsorcio
GO

CREATE UNIQUE CLUSTERED INDEX IDX_cluster_vista_consorcios_nombreConsorcio ON vista_consorcios(nombreConsorcio);
CREATE NONCLUSTERED INDEX IDX_ncluster_vista_consorcios_zona ON vista_consorcios(zona);
GO

/**/
CREATE VIEW vista_conserjes WITH SCHEMABINDING AS
	SELECT
		c.idconserje AS idConserje,
		conserje.apeynom AS nombreConserje,
		p.descripcion AS provincia,
		l.descripcion AS localidad
	FROM dbo.consorcio c 
		JOIN dbo.conserje  ON c.idconserje = conserje.idconserje
		JOIN dbo.provincia p ON c.idprovincia = p.idprovincia
		JOIN dbo.localidad l ON c.idprovincia = l.idprovincia AND c.idlocalidad = l.idlocalidad 
GO

CREATE UNIQUE CLUSTERED INDEX IDX_cluster_vista_conserje_idConserje ON vista_conserjes (idConserje);
CREATE NONCLUSTERED INDEX IDX_ncluster_vista_conserje_zona ON vista_conserjes (provincia);
GO

-------------------------------------------------------14/11------------------------------------------------------
/*
Definimos un vista donde la consula nos devolvera información sobre provincias (idprovincia, descripcion), localidades (descripcion) y consorcios (nombre).
Solo muestra las provincias que tienen asociado un consorcio.
*/

CREATE VIEW vista_provincia_consorcio_localidad WITH SCHEMABINDING AS
SELECT 
       p.idprovincia,
       p.descripcion AS "Provincia",
       l.descripcion AS "Localidad", 
	   c.nombre AS "Consorcio"
FROM  dbo.provincia p
JOIN  dbo.localidad l ON p.idprovincia = l.idprovincia
JOIN  dbo.consorcio c ON l.idprovincia = c.idprovincia AND l.idlocalidad = c.idlocalidad
GO
--index único agrupado
CREATE UNIQUE CLUSTERED INDEX UX_VistaProvinciaConsorcioLocalidad 
ON dbo.vista_provincia_consorcio_localidad (idprovincia, Provincia, Localidad, Consorcio);
GO

SELECT * FROM vista_provincia_consorcio_localidad
GO

------------------------------*-*-Vista de cada Tabla-*-*------------------------------------
/*
Crear la vista para filtrar información sensible del conserje
*/
CREATE VIEW dbo.VistaConserje WITH SCHEMABINDING AS
SELECT
    idconserje,
    apeynom AS nombre,
    tel AS telefono
FROM 
    dbo.conserje;
GO

-- Crear la vista indexada
CREATE UNIQUE CLUSTERED INDEX IX_VistaConserje_idconserje
ON dbo.VistaConserje (idconserje);
GO

/*
Crea una vista de la tabla Administrador que muestra solo el id y el nombre completo del administrador 
*/
CREATE VIEW dbo.VistaAdministradorWS WITH SCHEMABINDING AS
SELECT
     idadmin,
	 apeynom AS "Apellido y Nombre"
FROM
   dbo.administrador;
GO

--Crear la vista indexada
CREATE UNIQUE CLUSTERED INDEX IX_VistaAdministrador_idadmin
ON dbo.VistaAdministradorWS (idadmin);
GO

/*
Crea la vista correspondiente a la tabla Consorcio. Muestra solo la información del consorcio. 
*/
CREATE VIEW dbo.VistaConsorcio WITH SCHEMABINDING AS
SELECT
    idprovincia,
    idlocalidad,
    idconsorcio,
    nombre,
    direccion,
    idzona
FROM
    dbo.consorcio;
GO

-- Crear un índice en la tabla base (consorcio)
CREATE UNIQUE CLUSTERED INDEX IX_VistaConsorcio
ON dbo.VistaConsorcio (idprovincia, idlocalidad, idconsorcio);
GO



