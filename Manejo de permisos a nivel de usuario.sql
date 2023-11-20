
--Ingresas con log_ax ps: Pass1234
-- Crear el login
CREATE LOGIN log_ax WITH PASSWORD = 'Pass1234';

-- Usar la base de datos
USE base_consorcio;

-- Crear el usuario asociado al login
CREATE USER ax_user FOR LOGIN log_ax;

-- Crear un rol para las vistas
CREATE ROLE ViewOnly_Role;

-- Otorgar permisos SELECT en las vistas deseadas al rol 'ViewOnly_Role'
GRANT SELECT ON dbo.vista_provincia_consorcio_localidad TO ViewOnly_Role;
GRANT SELECT ON dbo.vista_conserjes TO ViewOnly_Role;
GRANT SELECT ON dbo.vista_consorcios TO ViewOnly_Role;
GRANT SELECT ON dbo.vista_gastos TO ViewOnly_Role;

-- Denegar permisos SELECT para tablas en consorcio
DENY SELECT ON dbo.administrador TO ViewOnly_Role;
DENY SELECT ON dbo.conserje TO ViewOnly_Role;
DENY SELECT ON dbo.consorcio TO ViewOnly_Role;
DENY SELECT ON dbo.gasto TO ViewOnly_Role;
DENY SELECT ON dbo.localidad TO ViewOnly_Role;
DENY SELECT ON dbo.provincia TO ViewOnly_Role;
DENY SELECT ON dbo.zona TO ViewOnly_Role;
DENY SELECT ON dbo.tipogasto TO ViewOnly_Role;
DENY SELECT ON dbo.inmueble TO ViewOnly_Role;

-- Asignar el rol al usuario 'axel_user'
EXEC sp_addrolemember 'ViewOnly_Role', 'ax_user';
-- Quitar el rol al usuario 'axel_user'
EXEC sp_droprolemember 'ViewOnly_Role', 'ax_user';

-------------------------------------------------------------
--Creación del usuario user_gab. Puede visualizar las tablas
-------------------------------------------------------------
CREATE LOGIN log_gab WITH PASSWORD = 'Pass1234';
USE base_consorcio;
CREATE USER user_gab FOR LOGIN log_gab;

--creacion de rol DBA
create role DBA_Role 

-- Permiso de administración de base de datos
grant control to DBA_Role

-- Permiso para crear, modificar y eliminar tablas
GRANT CREATE TABLE TO DBA_Role;
GRANT ALTER TO DBA_Role;
GRANT DELETE TO DBA_Role;

-- Asignar rol de DBA_Role a user_gab
USE base_consorcio;
EXEC sp_addrolemember 'DBA_Role', 'user_gab';

