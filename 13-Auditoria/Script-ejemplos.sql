--****************************************************
-- Administraci�n de bases de datos relacionales
-- Audtor�a
-- Autor: Erick Varela
-- Git: https://github.com/vareladev/administracion-bases-de-datos
-- Versi�n: 1.0
-- Fecha: Agosto 2018
--****************************************************

--SQL Plus: Crear una conexi�n con el usuario SYS.
SYS AS SYSDBA;

--SQL Plus: Verificar el valor del par�metro AUDIT
show parameter audit;

/*
Posibles valores:

	- none:			Auditor�a desactivada.
	- db:			Auditor�a activada y guarda los registros en la tabla SYS.AUD$ (tablespace SYSTEM por defecto).
	- os:			Auditor�a activada, con todos los registros guardados directamente en el sistema operativo, en un directorio y archivos concretos.
	- db, extended: Auditor�a activada, los datos se almacenar�n en la taba SYS.AUD$. Adem�s se escribir�n los valores correspondientes 
					en las columnas SqlText y SqlBind de la tabla SYS.AUD$.
	- xml:			Auditor�a activada, los sucesos ser� escritos en ficheros XML del sistema operativo.
	- xml, extended:Auditor�a activada, los sucesos ser� escritos en ficheros XML del sistema operativo, adem�s se incluir�n los
					valores de SqlText y SqlBind.
*/

--Modificar el valor del par�metro
ALTER SYSTEM SET audit_trail=db SCOPE=SPFILE;

/*
NOTA:
Para poder ejecutar los cambios es necesario reiniciar el proceso de la base de datos esto se logra desde SQL plus:
shutdown;
startup;
*/

/*
Atributo SCOPE:
par�metro que se usa junto con el comando ALTER SYSTEM cuando se est� cambiando el valor de alg�n par�metro de inicializaci�n del archivo spfile. 
Es vital entender c�mo usar este par�metro para lograr el efecto deseado. Hay tres valores que puede tomar el par�metro de SCOPE:
	- memory:		Oracle realizar� el cambio especificado por el comando alter system para la vida de la instancia. La pr�xima vez que se reinicie la base de datos, 
					por cualquier motivo, el cambio se revertir� al valor predeterminado.
	- spfile:		El cambio realizado en el comando ALTER SYSTEM tendr� lugar a partir del pr�ximo inicio, pero no afectar� a la instancia actual.
	- both:			Si desea que el comando ALTER SYSTEM se ejecute inmediatamente, se usa el valor de scope = both, que realizar� el cambio para la instancia actual 
					y lo conservar� a trav�s de cualquier reinicio futuro.
*/

--En SQL Developer: Con el usuario SYS, Crear el usuario anubis.
CREATE USER anubis
    IDENTIFIED BY 123
    DEFAULT TABLESPACE SYSTEM
    QUOTA 1M ON SYSTEM
    TEMPORARY TABLESPACE TEMP;

--Auditando conexiones:
--EN SQL plus: 
AUDIT SESSION BY anubis;

--En SQL Developer: Intentar crear una conexi�n con el usuario anubis (fallar� por falta de permisos)

--En SQL Developer: Con el usuario SYS realizar la siguiente consulta:
SELECT Username, userhost, extended_timestamp, action_name 
FROM dba_audit_session 
WHERE username='ANUBIS';

SELECT username, extended_timestamp, action_name, comment_text, priv_used
FROM dba_audit_trail 
WHERE username='ANUBIS'; 

----En SQL Developer: Con el usuario SYS, otorgar permiso de conexi�n al usuario anubis
GRANT CREATE SESSION TO anubis;

--En SQL Developer: Intentar crear una conexi�n con el usuario anubis. Esta vez la conexi�n tendr� exito

--En SQL Developer: Con el usuario SYS realizar la siguiente consulta:
SELECT Username, userhost, extended_timestamp, action_name 
FROM dba_audit_session 
WHERE username='ANUBIS';

SELECT username, extended_timestamp, action_name, comment_text, priv_used
FROM dba_audit_trail 
WHERE username='ANUBIS'; 

--Auditando instrucicones DDL:
--En SQL Developer: Terminar la conexi�n con el usuario ANUBIS
--En SQL Developer: Con el usuario SYS, otorgar permiso de creacion de tablas a anubis
GRANT CREATE TABLE TO anubis;

--EN SQL plus: 
AUDIT CREATE TABLE BY anubis;

--En SQL Developer: Iniciar una nueva conexi�n con el usuario ANUBIS, Crear la siguiente tabla
CREATE TABLE persona(
    codigo INT PRIMARY KEY,
    carnet CHAR(8),
    telefono CHAR(10)
);

--En SQL Developer: Con el usuario SYS realizar la siguiente consulta:
SELECT username,owner,obj_name,action_name,priv_used,extended_timestamp
FROM dba_audit_object 
WHERE username='ANUBIS';

--Auditando instrucciones DML:
--En SQL Developer: Terminar la conexi�n con el usuario ANUBIS
--EN SQL plus: 
AUDIT SELECT TABLE, UPDATE TABLE, INSERT TABLE, DELETE TABLE 
BY anubis 
BY ACCESS;

--En SQL Developer: Con el usuario SYS.
DELETE TABLE SYS.AUD$;

--En SQL Developer: Iniciar una nueva conexi�n con el usuario ANUBIS, Crear la siguiente tabla y hacer las siguientes operaciones
CREATE TABLE persona(
    codigo INT PRIMARY KEY,
    carnet CHAR(8),
    telefono CHAR(10)
);


INSERT INTO persona VALUES(1,'00012318','7777-7894');
SELECT * FROM persona;
DELETE FROM persona;

--En SQL Developer: Con el usuario SYS realizar la siguiente consulta:
SELECT username, extended_timestamp, action_name, comment_text, priv_used
FROM dba_audit_trail 
WHERE username='ANUBIS'; 


--Auditando instrucciones objetos especificos:
--En SQL Developer: Terminar la conexi�n con el usuario ANUBIS

--En SQL Developer: Con el usuario SYS, crear al usuario ISIS
CREATE USER isis
    IDENTIFIED BY 123
    DEFAULT TABLESPACE SYSTEM
    QUOTA 1M ON SYSTEM
    TEMPORARY TABLESPACE TEMP;
    
GRANT CREATE SESSION TO isis;

--EN SQL plus: 
AUDIT INSERT, DELETE, UPDATE ON anubis.persona BY ACCESS;
AUDIT INSERT, DELETE, UPDATE ON persona BY ACCESS;

/*
AUDIT puede utilizar 2 par�metros: BY ACCESS y BY SESSION, la diferencia es:
	- BY ACCESS:	Registra cada transacci�n realizada a un objeto auditado.
	- BY SESSION:	Registra solo una transacci�n realizada a un objeto auditado por sesion.
*/

--En SQL Developer: Iniciar una nueva conexi�n con el usuario ANUBIS y otorgar permisos de acceso a los recursos a ISIS
GRANT SELECT ON persona TO ISIS;
GRANT INSERT ON persona TO ISIS;
GRANT UPDATE ON persona TO ISIS;

--En SQL Developer: Con el usuario ISIS: realizar las siguientes sentencias.
INSERT INTO anubis.persona VALUES(11,'00012618','7222-7894');
SELECT * FROM anubis.persona;
COMMIT;

--En SQL Developer: Con el usuario SYS, 
SELECT username, userhost, timestamp, owner, obj_name, action_name 
FROM dba_audit_object 
WHERE obj_name='PERSONA';

--Auditor�a en xml
--SQL Plus: Verificar el valor del par�metro AUDIT
show parameter audit;

--SQL Plus: Modificar el valor del par�metro
ALTER SYSTEM SET audit_trail=xml SCOPE=SPFILE;

--SQL Plus: reiniciar la base
shutdown immediate
startup

--SQL Plus: crear usuario thot y osiris
CREATE USER THOT IDENTIFIED BY THOT;
CREATE USER OSIRIS IDENTIFIED BY OSIRIS;
GRANT CONNECT, RESOURCE TO THOT;
GRANT CONNECT, RESOURCE TO OSIRIS;
--SQL Plus: conectandose con el usuario THOT
CONNECT THOT/THOT
--SQL Plus: Crear tabla temple
CREATE TABLE temple (templeid INT);
INSERT INTO temple VALUES(13);
--SQL Plus: conectandose con el usuario SYS y auditar a la tabla:
CONNECT sys AS sysdba
AUDIT SELECT ON thot.temple;
--SQL Plus: conectandose con el usuario OSIRIS
CONNECT OSIRIS/OSIRIS
SELECT * FROM thot.temple WHERE templeid = 13;
--verificar donde esta guardando xml de auditoria:
CONNECT sys AS sysdba
SHOW PARAMETER AUDIT;

 

























