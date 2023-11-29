/*
Se va analizar el funcionamiento de procedimientos sobre una vista
y si es necesario aplicarlos sobre una vista o si es mejor utilizar la vista en otros contextos.
Tambien se aplicaran funciones sobre vista para obtener las denominadas vistas parametrizadas.
No satisface la solucion esperada.
*/
CREATE VIEW vista_actualizable WITH SCHEMABINDING
AS
SELECT a.apeynom, a.viveahi, a.tel, a.sexo
FROM dbo.administrador a
GO 

-- Se comprueba el funcionamiento y analisamos si es la mejor opcion --
SELECT * FROM vista_actualizable
WHERE viveahi= 'N';

-- Se realiza la actualizacion de un registro y analisamos la mejor opcion --
UPDATE vista_actualizable
SET viveahi = 'N'
FROM vista_actualizable
WHERE apeynom = 'Perez Juan Manuel'
GO 

UPDATE administrador
SET idadmin = 2
WHERE apeynom = 'Perez Juan Manuel'
GO 

-- Se crea el proceso --
CREATE PROCEDURE sp_actualizarCampoViveAhi 
	@apeynom VARCHAR(50),
	@viveahi VARCHAR(1),
	@exito BIT OUT,
	@error VARCHAR(200) OUT
AS
BEGIN
	IF not exists(SELECT * FROM vista_actualizable WHERE apeynom = @apeynom)
	BEGIN
		SET @exito = 0;
		SET @error = 'El apellido y nombre ingresados no existen';
		RETURN;
	END
	BEGIN TRY
		UPDATE vista_actualizable
		SET viveahi = @viveahi
		WHERE apeynom = @apeynom;
		SET @exito = 1;
	END TRY
	BEGIN CATCH
		SET @error = ERROR_MESSAGE()
	END CATCH
END

-- Realizamos la prueba que devuelve el error --
DECLARE @exito BIT;
DECLARE @error VARCHAR(200);

EXEC sp_actualizarCampoViveAhi 'Aguado Axel Tomas', 'N', @exito OUT, @error OUT

SELECT @error as msg_error, @exito as msg_exito
GO

-- Realizamos una funcion y la utilizamos para filtrar una vista --
-- Creamos la funcion que calcule la edad--
CREATE FUNCTION [fn_calcular_edad] (
	@fecha_nac DATE 
) RETURNS INT
AS
BEGIN
	RETURN DATEDIFF(YEAR, @fecha_nac, GETDATE())
END
GO

-- Comrpueba la existencia de la funcion--
IF OBJECT_ID('dbo.fn_calcular_edad', 'FN') is not null
	PRINT 'La funcion existe' 
ELSE 
	PRINT 'La funcion no existe';

DECLARE @fecha_nacimiento DATE 
SET @fecha_nacimiento= '1999-10-11'

SELECT dbo.fn_calcular_edad('1996-04-07') as edad
GO

-- Creamos la vista y aplicamos la funcion que calcula la edad --
CREATE VIEW vista_fn_edad
AS
SELECT apeynom, sexo, dbo.[fn_calcular_edad](fechnac) as edad
FROM dbo.administrador 
GO

-- Creamos la funcion que nos permita aplicar un filtro por edad --
CREATE FUNCTION fn_filtrar_edad_minima (
	@edadMinima INT
)
RETURNS TABLE
AS
RETURN  (
SELECT * FROM dbo.vista_fn_edad WHERE edad >= @edadMinima
)

SELECT * FROM fn_filtrar_edad_minima (39)