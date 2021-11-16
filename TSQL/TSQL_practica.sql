/*
1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”
*/

drop function ej1 --borra la funcion q ya existe, por si quiero hacer cambios. sino pongo alter en lugar de create.

create function ej1 (@producto char(8), @deposito char(2))
returns char(60)
as 
begin 
return (select case when stoc_cantidad > stoc_stock_maximo then 'DEPOSITO COMPLETO'
	else 'OCUPACION DEL DEPOSITO' + stoc_deposito +' ' + str(stoc_cantidad/stoc_stock_maximo*100,12,2)+'%' end
	from stock
	where stoc_producto = @producto and stoc_deposito = @deposito)
end


select dbo.ej1(stoc_producto,stoc_deposito)
from STOCK

/*
2. Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha
*/

create function ej2 (@articulo char(8), @fecha smalldatetime)
returns decimal(12,2)
as 
begin
	return (select sum(stoc_cantidad) from STOCK
			where @articulo = stoc_producto)
			+
			(select sum(item_cantidad) from Item_Factura
			 join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
			 where item_producto = @articulo and fact_fecha <=@fecha)
end

select dbo.ej2(item_producto, fact_fecha)
from Factura
join item_factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero

/*
3. Cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.

-> SI CAMBIA UNA TABLA ES UN PROCEDURE, UNA FUNCION NO CAMBIA UNA TABLA
*/

--entre parentesis es lo q retorna: output
create procedure ej3 (@cantidad numeric(3) output)
as
begin

	--declaro una variable
	declare @jefe numeric(6)

	select @cantidad = count(*) from empleado where empl_jefe is null
	
	if(@cantidad) > 1
		begin
			select top 1 @jefe = empl_codigo  --guardo el codigo en la variable jefe 
			from empleado
			where empl_jefe = null
			order by empl_salario desc, empl_ingreso asc

			--actualizo -> update TABLA set LO QUE QUIERO SETEAR
			update Empleado set empl_jefe = @jefe
			where empl_jefe is null and empl_codigo <> @jefe
		end
end

-- en una linea, no es recomendable
--create PROCEDURE ej3 (@cantidad numeric(3) output)
--as 
--begin 

--	select @cantidad = count(*) from Empleado where empl_jefe is null

--		update empleado set empl_jefe = (select top 1 empl_codigo from empleado
--										where empl_jefe is null
--										order by empl_salario desc, empl_ingreso)
--		where empl_jefe is null and empl_codigo <> (select top 1 empl_codigo from empleado
--													where empl_jefe is null
--													order by empl_salario desc, empl_ingreso)
--		END

/*
4.Cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.
*/

alter procedure ej4 (@vendedor numeric (6) output)
as 
begin

	update Empleado set empl_comision = (select sum(fact_total)
										 from factura
										 where empl_codigo = fact_vendedor 
										 and 
										 year(fact_fecha) = (select max(year(fact_fecha)) from Factura))

	select top 1 @vendedor = fact_vendedor
	from factura
	where year(fact_fecha) = (select max(year(fact_fecha)) from Factura)
	order by sum(fact_total) desc

end

--EN CLASE
alter PROCEDURE ej4 (@vendedor numeric(6) output)
AS
BEGIN

        update empleado set empl_comision = 
        (select sum(fact_total) from Factura 
         where empl_codigo = fact_vendedor
         and
         year(Fact_fecha) = (select max(year(fact_fecha)) from Factura))

		--cambia esto
        set @vendedor = (select top 1 fact_vendedor from factura 
        where year(Fact_fecha) = (select max(year(fact_fecha)) from Factura)
        order by fact_total )

        print @vendedor

END

declare @vend numeric(6)
exec ej4 @vend
select @vend

/*
5. Realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición:
	Create table Fact_table
	( anio char(4),
	mes char(2),
	familia char(3),
	rubro char(4),
	zona char(3),
	cliente char(6),
	producto char(8),
	cantidad decimal(12,2),
	monto decimal(12,2)
	)
	Alter table Fact_table
	Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)
*/

IF OBJECT_ID('Fact_table', 'U') IS NOT NULL
DROP TABLE Fact_table
GO

Create table Fact_table
	( anio char(4),
	mes char(2),
	familia char(3),
	rubro char(4),
	zona char(3),
	cliente char(6),
	producto char(8),
	cantidad decimal(12,2),
	monto decimal(12,2)
	)

Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)

create procedure ej5
as
begin
	insert Fact_table
	select year(fact_fecha),
			month(fact_fecha),
			prod_familia,
			prod_rubro,
			depa_zona,
			fact_cliente,
			prod_codigo,
			sum(item_cantidad),
			sum(item_precio*item_cantidad)
			
	 from factura
	 join item_factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
	 join producto on item_producto = prod_codigo
	 join Empleado on empl_codigo = fact_vendedor
	 join Departamento on depa_codigo = empl_departamento
	 group by year(fact_fecha),
			month(fact_fecha),
			prod_familia,
			prod_rubro,
			depa_zona,
			fact_cliente,
			prod_codigo
end

--PROBAR
exec dbo.ej5
select * from Fact_table

/*
6.Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas 
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.
*/

CREATE PROCEDURE SP_UNIFICAR_PRODUCTO
AS
BEGIN
    DECLARE @combo CHAR(8);
    DECLARE @combocantidad INTEGER;
    
    DECLARE @fact_tipo CHAR(1);
    DECLARE @fact_suc CHAR(4);
    DECLARE @fact_nro CHAR(8);
    
    
    DECLARE  cFacturas CURSOR FOR --CURSOR PARA RECORRER LAS FACTURAS
        SELECT fact_tipo, fact_sucursal, fact_numero
        FROM Factura ;
        /* where para hacer una prueba acotada
        where fact_tipo = 'A' and
                fact_sucursal = '0003' and
                fact_numero='00092476'; */
        
        OPEN cFacturas
        
        FETCH next FROM cFacturas
        INTO @fact_tipo, @fact_suc, @fact_nro
        
        WHILE @@FETCH_STATUS = 0
        BEGIN   
            DECLARE  cProducto CURSOR FOR
            SELECT comp_producto --ACA NECESITAMOS UN CURSOR PORQUE PUEDE HABER MAS DE UN COMBO EN UNA FACTURA
            FROM Item_Factura join Composicion C1 ON (item_producto = C1.comp_componente)
            WHERE item_cantidad >= C1.comp_cantidad AND
                  item_sucursal = @fact_suc AND
                  item_numero = @fact_nro AND
                  item_tipo = @fact_tipo
            GROUP BY C1.comp_producto
            HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion AS C2 WHERE C2.comp_producto= C1.comp_producto)
            
            OPEN cProducto
            FETCH next FROM cProducto INTO @combo
            WHILE @@FETCH_STATUS = 0 
            BEGIN
                        
                SELECT @combocantidad= MIN(FLOOR((item_cantidad/c1.comp_cantidad)))
                FROM Item_Factura join Composicion C1 ON (item_producto = C1.comp_componente)
                WHERE item_cantidad >= C1.comp_cantidad AND
                      item_sucursal = @fact_suc AND
                      item_numero = @fact_nro AND
                      item_tipo = @fact_tipo AND
                      c1.comp_producto = @combo --SACAMOS CUANTOS COMBOS PUEDO ARMAR COMO MÁXIMO (POR ESO EL MIN)
                
                --INSERTAMOS LA FILA DEL COMBO CON EL PRECIO QUE CORRESPONDE
                INSERT INTO Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
                SELECT @fact_tipo, @fact_suc, @fact_nro, @combo, @combocantidad, (@combocantidad * (SELECT prod_precio FROM Producto WHERE prod_codigo = @combo));              
 
                UPDATE Item_Factura  
                SET 
                item_cantidad = i1.item_cantidad - (@combocantidad * (SELECT comp_cantidad FROM Composicion
                                                                        WHERE i1.item_producto = comp_componente 
                                                                              AND comp_producto=@combo)),
                ITEM_PRECIO = (i1.item_cantidad - (@combocantidad * (SELECT comp_cantidad FROM Composicion
                                                            WHERE i1.item_producto = comp_componente 
                                                                  AND comp_producto=@combo))) *     
                                                    (SELECT prod_precio FROM Producto WHERE prod_codigo = I1.item_producto)                                                                                                       
                FROM Item_Factura I1, Composicion C1 
                WHERE I1.item_sucursal = @fact_suc AND
                      I1.item_numero = @fact_nro AND
                      I1.item_tipo = @fact_tipo AND
                      I1.item_producto = C1.comp_componente AND
                      C1.comp_producto = @combo
                      
                DELETE FROM Item_Factura
                WHERE item_sucursal = @fact_suc AND
                      item_numero = @fact_nro AND
                      item_tipo = @fact_tipo AND
                      item_cantidad = 0
                
                FETCH next FROM cproducto INTO @combo
            END
            CLOSE cProducto;
            deallocate cProducto;
            
            FETCH next FROM cFacturas INTO @fact_tipo, @fact_suc, @fact_nro
            END
            CLOSE cFacturas;
            deallocate cFacturas;
    END 

/*
7. Hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/

IF OBJECT_ID('Ventas','U') IS NOT NULL 
DROP TABLE Ventas
GO

CREATE TABLE Ventas
(
    vent_codigo CHAR(8) NULL,				--Código del articulo
    vent_detalle CHAR(50) NULL,				--Detalle del articulo
    vent_movimientos int NULL,				--Cantidad de movimientos de ventas (Item Factura)
    vent_precio_prom DECIMAL(12,2) NULL,	--Precio promedio de venta
    vent_renglon int  ,						--Nro de linea de la tabla
    vent_ganancia CHAR(6) NOT NULL,			--Precio de venta - Cantidad * Costo Actual
)

create procedure ej7(@fecha1 date, @fecha2 date)
as
begin
	declare @renglon int, @codigo char(8), @detalle char(50), @movimientos int, @precio decimal(12,2), @ganancia char(6)

	--el cursor va a ir por cada coso de la tabla de este select
	declare cursorArticulos cursor
	for select prod_codigo,
			   prod_detalle,
			   sum(item_cantidad),
			   avg(item_precio),
			   sum(item_precio*item_cantidad)
	from Producto
	join Item_Factura on item_producto = prod_codigo
	join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
	where fact_fecha between @fecha1 and @fecha2
	group by prod_codigo, prod_detalle


	--trabajamos con el cursor
	open cursorArticulos

		set @renglon = 0

		--me recorre la tabla de arriba y guarda los valores
		fetch next from cursorArticulos
		into @codigo, @detalle, @movimientos, @precio, @ganancia

		while @@FETCH_STATUS = 0 --es algo del cursor, si esta en 0 esta todo okey
		begin
			--aumento el renglon
			set @renglon = @renglon + 1

			--voy a insertar
			insert into Ventas
			values(@codigo, @detalle, @movimientos, @precio,@renglon,@ganancia)

			--paso al siguiente
			fetch next from cursorArticulos
			into @codigo, @detalle, @movimientos, @precio, @ganancia
		end

	close cursorArticulos
	deallocate cursorArticulos --como el liberar memoria

end


exec ej7()



--el que hizo mati

IF OBJECT_ID('Ventas','U') IS NOT NULL 
DROP TABLE Ventas
GO
CREATE TABLE Ventas
(
vent_codigo CHAR(8) NULL, --C�digo del articulo
vent_detalle CHAR(50) NULL, --Detalle del articulo
vent_movimientos int NULL, --Cantidad de movimientos de ventas (Item Factura)
vent_precio_prom DECIMAL(12,2) NULL, --Precio promedio de venta
vent_renglon int  , --Nro de linea de la tabla
vent_ganancia CHAR(6) NOT NULL, --Precio de venta - Cantidad * Costo Actual
)
/*
Alter table Ventas
Add constraint pk_ventas_ID primary key(vent_renglon)
GO*/
 
IF OBJECT_ID('Ejercicio7','P') IS NOT NULL
DROP PROCEDURE Ejercicio7
GO
 
CREATE PROCEDURE Ejercicio7 (@StartingDate DATE, @FinishingDate DATE)
AS
BEGIN
    DECLARE @Codigo CHAR(8), @Detalle CHAR(50), @Cant_Mov int, @Precio_de_venta DECIMAL(12,2), @Renglon int, @Ganancia DECIMAL(12,2)
    DECLARE cursor_articulos CURSOR
        FOR SELECT prod_codigo
            ,prod_detalle
            ,SUM(item_cantidad)
            ,AVG(item_precio)
            ,SUM(item_cantidad*item_precio)
            FROM Producto
                 JOIN Item_Factura
                    ON item_producto = prod_codigo
                 JOIN Factura
                    ON fact_tipo = item_tipo AND fact_sucursal = fact_sucursal AND fact_numero = item_numero
            WHERE fact_fecha BETWEEN @StartingDate AND @FinishingDate
            GROUP BY prod_codigo,prod_detalle
 
        OPEN cursor_articulos
        SET @renglon = 0
 
        FETCH NEXT FROM cursor_articulos
        INTO @Codigo,@Detalle,@Cant_Mov,@Precio_de_venta,@Ganancia
 
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Renglon = @Renglon + 1
            INSERT INTO Ventas
            VALUES (@Codigo,@Detalle,@Cant_Mov,@Precio_de_venta,@renglon,@Ganancia)
            FETCH NEXT FROM cursor_articulos
            INTO @Codigo,@Detalle,@Cant_Mov,@Precio_de_venta,@Ganancia
        END
        CLOSE cursor_articulos
        DEALLOCATE cursor_articulos
    END
GO

/*
8. Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas:
*/

Create function precioCombo (@producto char(8))
returns decimal(12,2)
as
	begin
		declare @costo decimal(12,2);
		declare @cantidad decimal(12,2);
		declare @componente char(8);
 
		if NOT EXISTS(SELECT * FROM Composicion WHERE comp_producto = @producto)
		begin
			set @costo = (select isnull(prod_precio,0) from Producto where prod_codigo=@producto)
			RETURN @costo
		end;
 
		set @costo = 0;
 
		declare cComp cursor for
		select comp_componente, comp_cantidad
		from Composicion 
		where comp_producto = @producto
 
		open cComp
		fetch next from cComp into @componente, @cantidad
		while @@FETCH_STATUS = 0
			begin
				set @costo = @costo + (dbo.FN_CALCULAR_SUMA_COMPONENTES(@componente) * @cantidad
				fetch next from cComp into @componente, @cantidad
			end
		close cComp;
		deallocate cComp;	
		return @costo;	
	end;


alter function precioCombo(@codigo char(8))
returns decimal(12,2)
as
begin
	declare @precio decimal(12,2)
	declare @cantidad numeric(4)
	declare @componente char(8)
	declare c1 cursor for
	select comp_componente, comp_cantidad from Composicion
	where comp_producto = @codigo

	set @precio = 0

	open c1
	fetch next from c1 into @componente, @cantidad
	if @@FETCH_STATUS <> 0
		begin
		close c1
		deallocate c1
		return (select prod_precio from Producto where prod_codigo = @codigo)
		end
	while @@FETCH_STATUS = 0
	begin
		select @precio = @precio + @cantidad * dbo.precioCombo(@componente)
		fetch next from c1 into @componente, @cantidad
	end		
	close c1
	deallocate c1


	return @precio
end

IF OBJECT_ID('Diferencias','U') IS NOT NULL 
DROP TABLE Diferencias
GO
CREATE TABLE Diferencias
(
dife_codigo CHAR(8) NULL, --C�digo del articulo
dife_detalle CHAR(50) NULL, --Detalle del articulo
dife_cantidad int NULL, --Cantidad de productos que conforman el combo
dife_precio_generado DECIMAL(12,2) NULL, --Precio que se compone a traves de sus componentes
dife_precio_facturado DECIMAL(12,2) NULL, --Precio del producto
)

IF OBJECT_ID('ej8','P') IS NOT NULL
DROP PROCEDURE ej8
GO
 

create procedure ej8
as
begin

	insert diferencias 
	select  item_producto, 
			prod_detalle,
			(select count(*) from Composicion where comp_producto = item_producto),
			dbo.precioCombo(item_producto),
			item_precio
	from Item_Factura join Producto on prod_codigo = item_producto
	where item_precio <> dbo.precioCombo(item_producto)
	and
	item_producto in (select comp_producto from Composicion)	
	
end


exec ej8
select * from Diferencias

/*
9. Crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.
*/

--ANTE ALGUNA MODIFICACION DE UN ITEM -> ES UN TRIGGER
--POR EJEMPLO si compro un combo big mac, bajo el stock de los componentes

create trigger ej9 on item_factura for insert, update
as
begin
	--contame cuantos de los q insertaron estan en la tabla de composicion
	if((select count(*) from inserted where item_producto in (select comp_producto from Composicion)) > 0)
	begin
	
		declare @codigo char(8), @cantidad int, @deposito char(2)
		declare c1 cursor 
            for select stoc_producto,
                       item_cantidad,
                       stoc_deposito
                from stock 
                    join Composicion on comp_producto = stoc_producto
					join inserted on item_producto = stoc_producto
                where stoc_producto in (select comp_componente from Composicion join inserted on item_producto = comp_producto)
                and stoc_deposito = (select right(item_sucursal,2) from inserted where comp_producto = item_producto)
				group by stoc_producto, item_cantidad, stoc_deposito
		
		open c1
		fetch next from c1
		into @codigo, @cantidad, @deposito

		while @@FETCH_STATUS = 0
			begin
				update stock
				set stoc_cantidad = stoc_cantidad - @cantidad
				where stoc_producto = @codigo and stoc_deposito = @deposito

				fetch next from c1
				into @codigo, @cantidad, @deposito
			end
		close c1
		deallocate c1
	end
end


/*
10. Crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.
*/
--MAL, USANDO AFTER/FOR -> se fija todo junto
create trigger ej10 on producto for delete
as
begin
	
	declare @cantidad int

	declare c1 cursor
	for select sum(stoc_cantidad)
		from stock
		where stoc_producto in (select prod_codigo from inserted)
		group by stoc_producto

	open c1
	fetch next from c1 into @cantidad
	while @@FETCH_STATUS = 0
	begin
		if @cantidad >0
			print('no se puede borrar')
			rollback --ESTO HACE Q NO SE BORRE, SI NO ENTRA AL IF SE BORRA SOLITO POR EL "CREATE TRIGGER .... FOR DELETE"
	end
	close c1
	deallocate c1
end

-- BIEN, USANDO INSTEAD OF -> se fija uno por uno -> EN ALGUN MOMENTO TENGO Q HACER UN DELETE DE PRODUCTO(DE LOS Q NO TIENEN STOCK)
-- USAMOS INSTEAD OF CUANDO: inserto 10 productos, quiero sacar los q empiezan con la letra A. hay uno solo q empieza con a. inserta el priemro, y se fija, inserta el segundo
-- y se fija. cuando llega al q esta mal, lo borra y sigue con el resto.
-- EL AFTER inserta todo junto de una, y si hay uno q no cumple saca TODO. 
--aca, los q cumple la condicion los muestra y los que no los borra

create trigger ej10 on producto INSTEAD OF delete
as
begin
	
	declare @producto char(8)
	declare c1 cursor for select prod_codigo from deleted

	open c1
	fetch next from c1 into @producto

	while @@FETCH_STATUS = 0
	begin
		if (select isnull(sum(stoc_cantidad),0) from stock where stoc_producto = @producto) > 0
			--si hay stock
			print('hay stock del producto: ' + @producto + ', no lo puedo borrar rey')
		else
			delete producto where prod_codigo = @producto

		fetch next from c1 into @producto
	end
	close c1
	deallocate c1
end

/*
11. Cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.
*/

create function ej11 (@codigo numeric(6))
returns int
as
begin

	declare @cuantosEmpleados int

	select @cuantosEmpleados = isnull(count(distinct empl_codigo),0) from empleado where @codigo = empl_jefe and empl_jefe < empl_codigo
	
	return @cuantosEmpleados + (select isnull(sum(dbo.ej11(empl_codigo)),0) from empleado where empl_jefe = empl_codigo)



	/*
	declare @devolver int

	select @cuantosEmpleados = count(distinct empl_codigo) from empleado where @codigo = empl_jefe and empl_jefe < empl_codigo

	if @cuantosEmpleados = 0
		set @devolver = 0
	else
		set @devolver = @cuantosEmpleados + (select sum(dbo.ej11(empl_codigo)) from empleado where empl_jefe = empl_codigo)

	return @devolver*/

end

/*
12. Cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.
*/

create function componenteCombo (@producto char(8), @componente char(8))
returns int
as
begin

	--declaro cursor para ir reorriendo a los hijos
	declare c1 cursor for select comp_componente from Composicion where @producto = comp_producto
	declare @hijo char(8)

	if @producto = @componente
		return 1
	
	open c1
		fetch next from c1 into @hijo
		
		while @@FETCH_STATUS = 0
		begin
			if dbo.componenteCombo(@componente, @hijo) = 1
				close c1
				deallocate c1
				return 1

			fetch next from c1 into @hijo
		end

	close c1
	deallocate c1

end

create trigger ej12 on composicion for insert,update
as 
begin
	
	--si da 1 la funcion, hay q sacar (rollback). Si todo el select da > 0 entonces hay al menos uno repetido. se fija por cada uno q se inserto si se cumple la cond
	if (select count(*) from inserted where dbo.componenteCombo(comp_producto,comp_componente) = 1) > 0
		rollback
end


insert Composicion values (12, '10001104','10001104')

select dbo.componeCombo('00001109','00001104')

/*
13. Cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías
*/

alter function calcularSalarioEmpleados(@empl_codigo numeric(6))
returns decimal(12,2)
as
begin

		declare @salarios decimal(12,2)

		select @salarios = isnull(sum(empl_salario),0) from empleado where @empl_codigo = empl_jefe

		return @salarios + (select isnull(sum(dbo.calcularSalarioEmpleados(empl_codigo)),0) from empleado where empl_jefe = empl_codigo)

end

alter trigger ej13 on empleado for update, insert
as
begin

	print('que haces gil, reparti la guita con todos gato')

	--si alguno tiene el salario mayor a la condicion -> rollback
	if(select count(*) from inserted where (dbo.calcularSalarioEmpleados(empl_codigo)*0.2) < empl_salario) > 0
		rollback

end


--pruebas
update Empleado set empl_salario = 100000 where empl_codigo = '1'

/*
14. Agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.
*/

--MAL, USANDO AFTER/FOR
create function calcularSumaPrecios(@producto char(8))
returns decimal(12,2)
as
begin
	
	declare @precios decimal (12,2)

	select @precios = isnull(sum(prod_precio* comp_cantidad) ,0) from Composicion join Producto on comp_componente = prod_codigo where comp_producto = @producto 

	return @precios

end

create trigger ej14 on factura for insert
as
begin

	declare @fecha smalldatetime
	declare @cliente char(6)
	declare @producto char(8)
	declare @precio decimal(12,2)

	if(select * from inserted 
		join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
		where (dbo.calcularSumaPrecios(item_producto)>item_precio) and item_producto in (select comp_producto from Composicion)) >0
		begin
			declare c1 cursor for select fact_fecha from  inserted 
			join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
			where (dbo.calcularSumaPrecios(item_producto)>item_precio) and item_producto in (select comp_producto from Composicion)

			open c1
			fetch next from c1 into @fecha, @cliente, @producto, @precio

			while @@FETCH_STATUS =0
			begin
				if(dbo.calcularSumaPrecios(@producto)/2) > @precio
					close c1
					deallocate c1
					rollback

					print(@fecha + ', ' + @cliente + ', ' + @producto + ', ' + @precio)
					fetch next from c1 into @fecha, @cliente, @producto, @precio
			end
			close c1
			deallocate c1

		end

end

--BIEN, USANDO INSTEAD OF
create function calcularSumaPrecios(@producto char(8))
returns decimal(12,2)
as
begin
	
	declare @precios decimal (12,2)

	select @precios = isnull(sum(prod_precio* comp_cantidad) ,0) from Composicion join Producto on comp_componente = prod_codigo where comp_producto = @producto 

	return @precios

end


CREATE TRIGGER EJ14v2 ON ITEM_FACTURA INSTEAD OF INSERT
AS
BEGIN
    DECLARE @PRODUCTO CHAR(8), @PRECIO DECIMAL(12,2), @CANTIDAD DECIMAL(12,2)
    DECLARE @FECHA SMALLDATETIME, @CLIENTE CHAR(6)
    DECLARE @TIPO CHAR, @SUCURSAL CHAR(4), @NUMERO CHAR(8)
	--declaro cursor para recorrer lo q inserta
    DECLARE cursorProd cursor for select item_tipo, item_sucursal, item_numero, item_producto, item_precio, item_cantidad from inserted

    open cursorprod
    fetch next from cursorProd into @tipo, @sucursal, @numero, @producto, @precio, @cantidad

    while @@FETCH_STATUS = 0
    begin
		--me fijo la condicion
        if (@precio > dbo.calcularSumaPrecios(@producto) / 2)
            begin
				--si cumple, lo inserta
                insert item_factura values (@tipo, @SUCURSAL, @NUMERO,@producto,@CANTIDAD,@precio)
                print('FECHA: ' + @fecha + ' CLIENTE: ' + @cliente + ' PRODUCTO: ' + @producto + ' PRECIO: ' + @precio)
            end
        ELSE
            BEGIN
				--borra toda la factura pq ya se anunla todo
                delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
                delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo
                print('El precio no puede ser menor a la mitad. ')
                break
            END
        fetch next from cursorProd into @tipo, @sucursal, @numero, @producto, @precio, @cantidad
    end
    CLOSE cursorProd
    deallocate cursorProd
END


/*
15. Cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.
*/

alter function ej15(@producto char(8))
returns decimal(12,2)
as
begin

	declare @precioFinal decimal(12,2)

	if(@producto not in (select comp_producto from Composicion))
		select @precioFinal = prod_precio from Producto where prod_codigo = @producto
	else
		begin

			select @precioFinal = isnull(sum(dbo.ej15(comp_componente)*comp_cantidad),0) 
			from Composicion 
			where comp_producto = @producto
			
		end

	return @precioFinal

end

select dbo.ej15(prod_codigo), prod_codigo from Producto

/*
16. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.
*/

create trigger ej16 on item_factura for insert
as
begin

	declare @producto char(8), @cantidad decimal(12,2), @deposito char(2), @cantidadStock decimal(12,2), @ultimoDesposito char(2)
	declare c1 cursor for select item_producto, item_cantidad from inserted
	
	open c1
	fetch next from c1 into @producto, @cantidad

	while @@FETCH_STATUS = 0
	begin
		declare cstock cursor for select stoc_deposito, stoc_cantidad from STOCK where stoc_producto=@producto order by stoc_cantidad desc
		
		open cstock
		fetch next from cstock into @deposito, @cantidadStock

		while @@FETCH_STATUS = 0
		begin
		
			if(@cantidad <= @cantidadStock)
			begin
				update stock set stoc_cantidad = stoc_cantidad-@cantidad where stoc_producto = @producto and stoc_deposito = @deposito
				set @cantidad = 0
				break
			end
			else
			begin
				update stock set stoc_cantidad = stoc_cantidad-@cantidad where stoc_producto = @producto and stoc_deposito = @deposito
				set @cantidad = @cantidad - @cantidadStock
			end
			set @ultimoDesposito = @deposito
			fetch next from cstock into @deposito, @cantidadStock
		end
		
		if (@cantidad = 0)
		begin
			update stock set stoc_cantidad = stoc_cantidad-@cantidad where stoc_producto = @producto and stoc_deposito = @ultimoDesposito
		end
		
		close cstock
		deallocate cstock
		fetch next from c1 into @producto, @cantidad

	end
	close c1
	deallocate c1
end


--clase
create trigger ej16 on item_factura for insert
as
begin
	
	declare @producto char(8), @cantidad decimal(12,2), @deposito char(2), @cantidad2 decimal(12,2), @anterior char(2)
	declare cVenta cursor for select i.item_producto, i.item_cantidad from inserted i

	open cVenta
	fetch next from cVenta into @Producto, @cantidad
	while @@FETCH_STATUS = 0
	begin
		declare cstock cursor  for select stoc_deposito, stoc_cantidad from stock where stoc_producto = @producto order by stoc_cantidad desc
		open cstock
		fetch next from cstock into @deposito, @cantidad2
		while @@FETCH_STATUS = 0
		begin
			if (@cantidad2 >= @cantidad)
			begin
				set @cantidad = 0
				update stock set stoc_cantidad = stoc_cantidad - @cantidad where stoc_producto = @producto and stoc_deposito = @deposito
				break
			end
			else
			begin
				update stock set stoc_cantidad = stoc_cantidad - @cantidad where stoc_producto = @producto and stoc_deposito = @deposito
				set @cantidad = @cantidad - @cantidad2
			end
			set @anterior = @deposito
			fetch next from cstock into @deposito, @cantidad2
		end

		if @cantidad > 0
			update stock set stoc_cantidad = stoc_cantidad - @cantidad where stoc_producto = @producto and stoc_deposito = @anterior
		close cstock
		deallocate cstock
		fetch next from cVenta into @Producto, @cantidad
	end
	close cventa
	deallocate cventa

end

/*
17. Sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock
*/

--es con for, con instead of no hace los insert solo. es un quilombo. es mas facil q haga todo y de ultima, hacer rollback.
create trigger ej17 on stock for update, insert
as
begin

	declare @cantidad decimal(12,2), @deposito char(2), @producto char(8), @maximo decimal(12,2), @minimo decimal(12,2)
	declare c1 cursor for select stoc_producto, stoc_cantidad, stoc_deposito, stoc_stock_maximo, stoc_punto_reposicion from inserted

	open c1
	fetch next from c1 into @producto, @cantidad, @deposito, @maximo, @minimo

	while @@FETCH_STATUS =0
	begin
		if(@cantidad > @maximo)
			print ('estas superando el stock maximo, no se puede')
			rollback
		else if(@cantidad <@minimo)
			print ('hay q reponer')
		fetch next from c1 into @producto, @cantidad, @deposito, @maximo, @minimo
	end
	close c1
	deallocate c1
end

/*
18. Sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas
*/

create function totalFacturasDelMes(@cliente char(6), @mes smalldatetime)
returns decimal(12,2)
as
begin
	declare @totalMeses decimal (12,2)
	select @totalMeses =sum(fact_total) from factura where MONTH(fact_fecha) = @mes and fact_cliente = @cliente

	return @totalMeses
end

create trigger ej18 on factura for insert
as
begin
	declare @cliente char(6), @totalFactura decimal(12,2), @mes smalldatetime, @limiteCliente decimal(12,2)
	declare cursorFactura cursor for select fact_cliente, fact_total, MONTH(fact_fecha) from inserted

	open cursorFactura
	fetch next from cursorFactura into @cliente, @totalFactura, @mes

	while @@FETCH_STATUS = 0
	begin
		select @limiteCliente = clie_limite_credito from Cliente where clie_codigo = @cliente

		if(@limiteCliente < @totalFactura + dbo.totalFacturasDelMes(@cliente, @mes))
			rollback

		fetch next from cursorFactura into @cliente, @totalFactura, @mes
	end
	close cursorFactura
	deallocate cursorFactura
end

/*
19. Cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.
*/

create function calcularAntiguedad(@empleado decimal(6,0))
returns smalldatetime
as
begin
	declare @antiguedad smalldatetime
	select @antiguedad = datediff(year, empl_ingreso, GETDATE()) from Empleado where empl_codigo=@empleado
	return @antiguedad
end

create function cantidadEmpleados(@empleado numeric(6,0))
returns int
as
begin
	declare @cantidadEmpleados int

	select @cantidadEmpleados = count(distinct empl_codigo) from empleado where @empleado = empl_jefe

	return @cantidadEmpleados + (select isnull(sum(dbo.cantidadEmpleados(empl_codigo)),0) from empleado where empl_jefe = @empleado)
end


create trigger ej19 on empleado for insert, update, delete
as
begin
	
	declare @empleado numeric(6,0), @jefe numeric (6,0)

	if(select count(*) from inserted) > 0
	begin
		declare cursorEmpleado cursor for select empl_codigo, empl_jefe from inserted

		open cursorEmpleado 
		fetch next from cursorEmpleado into @empleado, @jefe
	
		while @@FETCH_STATUS = 0
		begin
			--HAY Q VER SI EL EMPLEADO ES JEFE ANTES
			if(dbo.calcularAntiguedad(@empleado) < 5 and exists(select * from Empleado where empl_jefe=@empleado))
				rollback
			else 
			begin	
				if(dbo.cantidadEmpleados(@empleado) > (select floor(count(*)*0.5) from empleado) and @jefe <> NULL)
					rollback
			end

			fetch next from cursorEmpleado into @empleado, @jefe
		end
		close cursorEmpleado
		deallocate cursorEmpleado
		end
	else
	begin
		if(select empl_jefe from empleado group by empl_jefe having count(*) > (select count(*) from empleado)/2)
			rollback
	end

end

/*
20. Crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.
*/

alter function ventaMensual(@empleado numeric(6,0), @mes smalldatetime)
returns decimal(12,2)
as
begin
	declare @ventaTotalMes decimal(12,2)
	select @ventaTotalMes = isnull(sum(fact_total),0) from Factura where @empleado = fact_vendedor and @mes = month(fact_fecha)
	return @ventaTotalMes
end

create function adicionalProducto(@empleado numeric(6,0), @mes smalldatetime)
returns decimal(12,2)
as
begin
	declare @cantidad int

	select @cantidad = count(distinct item_producto)
	from Item_Factura 
	join factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
	where month(fact_fecha) = @mes and fact_vendedor=@empleado

	if(@cantidad > 50)
		return 0.08
		
	return 0.05

end

alter trigger ej20 on factura for insert
as
begin

	declare @vendedor numeric(6,0), @mes smalldatetime
	declare cursorFactura cursor for select fact_vendedor, MONTH(fact_fecha) from inserted

	open cursorFactura
	fetch next from cursorFactura into @vendedor, @mes

	while @@FETCH_STATUS = 0
	begin
		
		update empleado set empl_comision = dbo.ventaMensual(@vendedor,@mes) * dbo.adicionalProducto(@vendedor,@mes)

		fetch next from cursorFactura into @vendedor, @mes
	end
	close cursorFactura
	deallocate cursorFactura

end

/*
21. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.
*/

create function contarFamiliasDistintas (@claveFactura char(13))
returns int
as
begin 
	declare @cantidad int

	select @cantidad = count(distinct prod_familia) 
						from Item_Factura 
						join Producto on item_producto = prod_codigo
						where @claveFactura = item_tipo+item_sucursal+item_numero

	return @cantidad
end


--ASI PENSAMOS NOSOTROS, PERO CON INSTEAD OF ES MAS DIFICIL EL INSERT, FALTARIA HACER EL INSERT
create trigger ej21 on Factura instead of insert
as
begin
	
	declare @fact_tipo char(1),
            @fact_sucursal char(4),
            @fact_numero char(8),
            @fact_fecha smalldatetime,
            @fact_vendedor numeric(6),
            @fact_total decimal(12,2),
            @fact_total_impuestos decimal(12,2),
            @fact_cliente char(6) 

	declare cursorFactura cursor for select fact_tipo, fact_sucursal, fact_numero, fact_fecha,
            fact_vendedor ,
            fact_total ,
            fact_total_impuestos ,
            fact_cliente  
			from inserted 

	open cursorFactura
	fetch next from cursorFactura into @fact_tipo, @fact_sucursal, @fact_numero,
                                @fact_fecha,
                                @fact_vendedor,
                                @fact_total ,
                                @fact_total_impuestos ,
                                @fact_cliente 

	while @@FETCH_STATUS =0 
	begin
		
		if(dbo.contarFamiliasDistintas(@fact_tipo + @fact_sucursal + @fact_numero) > 1)
		begin
		--BORRA TODOS LOS ITEM FACTURA Q CUMPLAN LA CONDICION
			 delete from item_factura where item_tipo+item_sucursal+item_numero= @fact_tipo+@fact_sucursal+@fact_numero
             delete from factura where fact_tipo+fact_sucursal+fact_numero= @fact_tipo+@fact_sucursal+@fact_numero
             print('SE ELIMINO LA FACTURA')
			 break
		end
		else
		begin
			insert into factura values( @fact_tipo, @fact_sucursal, @fact_numero,
                                                @fact_fecha,
                                                @fact_vendedor,
                                                @fact_total ,
                                                @fact_total_impuestos ,
                                                @fact_cliente)
		end

		fetch next from cursorFactura into @fact_tipo, @fact_sucursal, @fact_numero,
                                @fact_fecha,
                                @fact_vendedor,
                                @fact_total ,
                                @fact_total_impuestos ,
                                @fact_cliente 
	end
	close cursorFactura
	deallocate cursorFactura

end

--USANDO FOR, SIN HACER EL INSERT
create trigger ej21 on Factura for insert
as
begin
    DECLARE @tipo CHAR, @sucursal CHAR(4), @numero CHAR(8)
    DECLARE c_Fact cursor for select fact_tipo, fact_sucursal, fact_numero from inserted

    if exists (select fact_tipo+fact_sucursal+fact_numero from inserted where dbo.contarFamiliasDistintas(fact_tipo+fact_sucursal+fact_numero) <> 1)
    begin
        open c_Fact
        fetch next from c_Fact into @tipo,@sucursal,@numero
        while @@FETCH_STATUS = 0
        begin
            delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@sucursal+@tipo
            delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@sucursal+@tipo
            fetch next from c_Fact into @tipo,@sucursal,@numero
        end
        close c_fact
        deallocate c_fact
        raiserror('no se puede ingresar productos de una familia distinta en una misma factura',1,1)
    end
end

/*
22. Se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.
*/

create function contarProductosParaRubro(@rubr_id char(4))
returns int
as
begin
	declare @cantidad int

	select @cantidad = count(prod_codigo) from Producto where prod_rubro= @rubr_id

	return @cantidad
end


create procedure distribuirProductos(@rubr_id char(4), @cantidadAguardar int)
as
begin
	
	declare @nuevoRubro char(4), @cantidadDisponible int, @i int

	set @i = 0

	select top 1 @nuevoRubro = prod_rubro from Producto where dbo.contarProductosParaRubro(@nuevoRubro) < 20

	set @cantidadDisponible = 20-dbo.contarProductosParaRubro(@nuevoRubro)

	if(@cantidadDisponible >= @cantidadAguardar)
	--se guarda todo
	begin
		
		while(@i < @cantidadAguardar) 
		begin
			
			update producto set prod_rubro = @nuevoRubro where prod_rubro = @rubr_id

			set @i = @i + 1
		end
	end

	else if (@cantidadDisponible < @cantidadAguardar)
	--se guarda una parte y recursividad
	begin
		while(@i < @cantidadDisponible) 
		
			declare @pasar int
			set @pasar = @cantidadAguardar - @cantidadDisponible
		
			begin
			
				update producto set prod_rubro = @nuevoRubro where prod_rubro = @rubr_id

				set @i = @i + 1
			end

			exec dbo.distribuirProductos @rubr_id, @pasar
	end
	else if(@nuevoRubro = NULL)
	--creo nuevo rubro y guardo todo
	begin
		insert into Rubro values('xx','RUBRO REASIGNADO')
		exec dbo.distribuirProductos @rubr_id, @cantidadAguardar
	end

end


create procedure ej22 
as
begin
	
	declare @rubr_id char(4)
	declare cursorRubros cursor for select rubr_id from Rubro

	fetch next from cursorRubros into @rubr_id

	while @@FETCH_STATUS =0
	begin
		declare @cantidadProductosEnRubro int

		set @cantidadProductosEnRubro = dbo.contarProductosParaRubro(@rubr_id)

		if (@cantidadProductosEnRubro > 20)
		begin
			declare @cantidadAguardar int
			set @cantidadAguardar = @cantidadProductosEnRubro - 20
			exec dbo.distribuirProductos @rubr_id, @cantidadAguardar
		end

		fetch next from cursorRubros into @rubr_id
	end
	close cursorRubros
	deallocate cursorRubros
end

--FRAN CON CURSOR
/*
CREATE PROCEDURE ej22
AS
BEGIN
    DECLARE @rubro char(4)
    DECLARE c1 CURSOR for
        select rubr_id from Rubro
    open c1
    FETCH NEXT FROM c1 INTO @rubro
    while @@FETCH_STATUS = 0
        BEGIN

            WHILE (SELECT count(distinct prod_codigo) from Producto where prod_rubro = @rubro) > 20
                BEGIN
                    IF (select count(distinct prod_rubro) from Producto where prod_rubro in (
                        select prod_rubro from Producto    group by prod_rubro
                        HAVING count(distinct prod_codigo)<20))>0
                        BEGIN
                            UPDATE Producto
                            set prod_rubro = (select top 1 prod_rubro from Producto group by prod_rubro
                                                HAVING count(distinct prod_codigo)<20)
                            where prod_codigo = (select top 1 prod_codigo from Producto where prod_rubro = @rubro)

                        END
                    --ELSE ACA IRIA LO DEL RUBRO EN LA MISMA FAMILIA, PERO NO ENTIENDO

                END

            FETCH NEXT FROM c1 INTO @rubro
        END
    close c1
    deallocate c1 
END*/

/*
23. Desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.
*/

alter function contarComposicionFactura(@factura char(14))
returns int
as
begin
	declare @cantidad int
	select @cantidad = count(distinct item_producto) 
		from Item_Factura 
		where @factura = item_tipo+item_sucursal+item_numero
		and
		item_producto in (select comp_producto from Composicion)

		return @cantidad
end

create trigger ej23 on factura for insert
as
begin
	DECLARE @tipo CHAR, @sucursal CHAR(4), @numero CHAR(8)

	declare c1 cursor for select fact_tipo, fact_sucursal, fact_numero from inserted

	open c1
	fetch next from c1 into @tipo, @sucursal, @numero

	while @@FETCH_STATUS = 0
	begin

		if(dbo.contarComposicionFactura(@tipo+@sucursal+@numero) > 2)
		begin
			delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
			delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo
		end

		fetch next from c1 into @tipo, @sucursal, @numero	
	end
	close c1
	deallocate c1

end

/*
24. Se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.
*/

create function encargadoOtraZona(@zona char(3), @encargado numeric(6))
returns int
as
begin
	declare @zonaEncargado char(3)

	select @zonaEncargado = depa_zona 
		from Empleado
		join Departamento on empl_departamento = depa_codigo

	if(@zona = @zonaEncargado)
		return 0

	return 1
end

create procedure cambiarEncargado (@deposito char(2), @zona char(3))
as
begin
	declare @nuevoEncargado numeric(6)

	select TOP 1 @nuevoEncargado = empl_codigo 
		from Empleado
		join Departamento on empl_departamento = depa_codigo
		join deposito on depo_encargado = empl_codigo
		where depa_zona = @zona
		group by empl_codigo
		order by count(distinct depo_codigo) asc

	update deposito set depo_encargado = @nuevoEncargado where depo_codigo = @deposito
end

create procedure ej24
as
begin
	declare @encargado numeric(6), @zona char(3), @deposito char(2)
	declare c1 cursor for select depo_codigo,depo_encargado, depo_zona from deposito

	open c1
	fetch next from c1 into @deposito, @encargado, @zona

	while @@FETCH_STATUS = 0
	begin
		
		if(dbo.encargadoOtraZona(@zona,@encargado) = 1)
		begin

			exec dbo.cambiarEncargado @deposito, @zona 

		end

	end
	close c1
	deallocate c1

end

--FRAN
CREATE PROCEDURE ej24
AS
BEGIN
	DECLARE @depoDefectuoso char(2)
	DECLARE c1 CURSOR FOR
		select depo_codigo
		from DEPOSITO join Empleado on depo_encargado = empl_codigo join Departamento on depa_codigo = empl_departamento
			join zona on zona_codigo = depa_zona
		where depo_zona != zona_codigo
		
		open c1
		FETCH NEXT FROM c1 INTO  @depoDefectuoso
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				UPDATE DEPOSITO
				set depo_encargado = (select top 1 empl_codigo from Empleado join Departamento on depa_codigo = empl_departamento
																			 join DEPOSITO on depo_encargado = empl_codigo
										where depo_zona = depa_zona and @depoDefectuoso = depo_codigo
										group by empl_codigo
										order by count(*) asc)
				where @depoDefectuoso = depo_codigo

				FETCH NEXT FROM c1 INTO  @depoDefectuoso
			END
			close c1
			deallocate c1

END

/*
25. Desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A 
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.
*/

create trigger ej25 on composicion for insert, update
as begin 
        declare @producto char(8)
        declare @componente char(8)

    declare c1 cursor for select comp_producto, comp_componente from inserted

    open c1
    fetch next from c1 into @producto, @componente

    while @@fetch_status = 0
    begin 

        if (select isnull(count(comp_producto),0) from composicion where comp_producto = @componente and @producto = comp_componente) > 0
                rollback 

    fetch next from c1 into @producto, @componente
    end

    close c1
    deallocate c1

end

----FRAN
CREATE TRIGGER ej25 on Composicion for insert,update 
AS 
	DECLARE @producto char(8), @componente char(8)
	DECLARE c1 CURSOR for
		select comp_producto,comp_componente from inserted 
	open c1
	FETCH NEXT FROM c1 into @producto,@componente

	WHILE @@FETCH_STATUS = 0
		begin
				
					if (select count(*) from composicion where @producto=comp_componente and @componente = comp_producto) > 0 
						BEGIN
							if (select count(*) from deleted) >0
								BEGIN
									DELETE FROM COMPOSICION WHERE @componente=comp_componente and @producto=comp_producto
								END

							ELSE 
								BEGIN
									UPDATE Composicion
									SET comp_componente = (select comp_componente from deleted where comp_producto = @producto)
									where comp_producto = @producto and comp_componente = @componente
								END
						END
						FETCH NEXT FROM c1 into @producto
		end
		close c1
		deallocate c1

/*
26. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
*/
create function tieneComponentesFactura(@factura char(14))
returns int
as
begin
	declare @cantidad int
	select @cantidad = count(distinct item_producto) 
		from Item_Factura 
		where @factura = item_tipo+item_sucursal+item_numero
		and
		item_producto in (select comp_componente from Composicion)

	if(@cantidad > 0)
		return 1

	return 0
end

create trigger ej26 on factura for insert
as
begin
	DECLARE @tipo CHAR, @sucursal CHAR(4), @numero CHAR(8)

	declare c1 cursor for select fact_tipo, fact_sucursal, fact_numero from inserted

	open c1
	fetch next from c1 into @tipo, @sucursal, @numero

	while @@FETCH_STATUS = 0
	begin

		if(dbo.tieneComponentesFactura(@tipo+@sucursal+@numero) = 1)
		begin
			delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
			delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo

			print('rompiste todo')
		end

		fetch next from c1 into @tipo, @sucursal, @numero	
	end
	close c1
	deallocate c1

end
/*
27. Se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.
*/

create function hayQueReasignar(@encargado numeric(6))
returns int
as
begin
	if(@encargado in (select empl_jefe from empleado) and @encargado in (select clie_vendedor from Cliente))
		return 1
	return 0
end


create procedure cambiarEncargado27(@deposito char(2))
as
begin
	declare @nuevoeEncargado numeric(6)
	select top 1 @nuevoeEncargado = empl_codigo from Empleado 
								join deposito on depo_encargado=empl_codigo
								where dbo.hayQueReasignar(empl_codigo) = 0
								group by empl_codigo
								order by count(distinct depo_codigo) asc

	if(@nuevoeEncargado != NULL)
		update DEPOSITO set depo_encargado = @nuevoeEncargado where depo_codigo = @deposito
	else
		print('NO HAY EMPLEADOS')
end


create procedure ej27 
as
begin
	declare @deposito char(2)
	declare c1 cursor for select depo_codigo from deposito

	open c1
	fetch next from c1 into @deposito

	while @@FETCH_STATUS =0
	begin
		exec dbo.cambiarEncargado27 @deposito
		fetch next from c1 into @deposito
	end
	close c1
	deallocate c1
end

/*
28. Se requiere reasignar los vendedores a los clientes. Para ello se solicita que
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendió más facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deberá asignar el vendedor con más
venta de la empresa, o sea, el que en monto haya vendido más.
*/

create function contarFacturasVendedor(@cliente char(6), @vendedor numeric(6,0))
returns int
as
begin
	
	declare @cantidad int
	select @cantidad = count(distinct fact_tipo+fact_sucursal+fact_numero)
					from Factura
					where fact_cliente = @cliente and fact_vendedor=@vendedor

	return @cantidad

end


create procedure cambiarVendedor(@cliente char(6))
as
begin
	
	declare @vendedor numeric(6,0)



end


create procedure ej28
as
begin

	declare @cliente char(6)
	declare c1 cursor for select clie_codigo from Cliente

	open c1
	fetch next from c1 into @cliente

	while @@FETCH_STATUS =0
	begin
		
		exec dbo.cambiarVendedor @cliente
	
		fetch next from c1 into @cliente
	end
	close c1
	deallocate c1
	
end

--
alter function vendedorQueMasLeVendio( @cliente char(6))
returns numeric (6)
as begin 
            declare @vendedor numeric(6)

            select top 1 @vendedor=fact_vendedor 
            from factura where @cliente = fact_cliente
            group by fact_cliente, fact_vendedor
            order by count(fact_vendedor) desc

            return isnull(@vendedor, (select top 1 fact_vendedor
                                        from factura
                                        group by fact_vendedor
                                        order by  sum(fact_total) desc))
end 


create procedure ej28
as begin 

    declare @cliente char(6),
     @vendedor numeric(6)

    declare c1 cursor for 
    select clie_codigo
    from cliente

    open c1
    fetch next from c1 into @cliente
    while @@FETCH_STATUS = 0
    begin 

            select @vendedor = dbo.vendedorQueMasLeVendio(@cliente)

            update cliente
            set clie_vendedor = @vendedor where clie_codigo = @cliente 


    fetch next from c1 into @cliente
    end 

    close c1
    deallocate c1
end


/*
29. Desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.
*/
--como el 26, pero aca no podes comprar un componente q sea componente de diferentes productos
create function tieneComponentesDistintosFactura(@factura char(14))
returns int
as
begin
	declare @cantidad int
	declare c1 cursor for select count(distinct comp_producto) 
			from  composicion
			join Item_Factura on item_producto=comp_componente 
			where @factura = item_tipo+item_sucursal+item_numero
			group by comp_componente

	open c1
	fetch next c1 into @cantidad

	while @@FETCH_STATUS = 0
	begin
		if(@cantidad > 1)
			close c1
			deallocate c1
			return 1
	end
	close c1
	deallocate c1
	return 0
end

create trigger ej29 on factura for insert
as
begin
	DECLARE @tipo CHAR, @sucursal CHAR(4), @numero CHAR(8)

	declare c1 cursor for select fact_tipo, fact_sucursal, fact_numero from inserted

	open c1
	fetch next from c1 into @tipo, @sucursal, @numero

	while @@FETCH_STATUS = 0
	begin

		if(dbo.tieneComponentesDistintosFactura(@tipo+@sucursal+@numero) = 1)
		begin
			delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
			delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo

			print('rompiste todo')
		end

		fetch next from c1 into @tipo, @sucursal, @numero	
	end
	close c1
	deallocate c1

end

/*
30. Agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar más de 100 unidades en el mes de ningún producto, si esto
ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha
superado el límite máximo de compra de un producto”. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.
*/

create function cantProductoMes(@mes smalldatetime, @cliente char(6), @producto char (8))
returns int
as
begin
	
	declare @cantidad int

	select @cantidad = sum(item_cantidad) 
					from Item_Factura
					join Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
					where month(fact_fecha) = @mes
					and fact_cliente = @cliente
					and item_producto = @producto
	return @cantidad
end


create trigger ej30 on item_Factura instead of insert
as
begin
	declare @tipo char, @sucursal char(4), @numero char(8), @producto char(8), @precio decimal(12,2), @fecha smalldatetime, @cliente char(6), @cantidad decimal(12,2)
	declare c1 cursor for select item_tipo, item_sucursal, item_numero, item_producto,item_precio, fact_fecha, fact_cliente,item_cantidad
	from inserted join factura on item_tipo + item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
	order by item_tipo,item_sucursal,item_numero

	open c1
	fetch next from c1 into @tipo, @sucursal, @numero, @producto, @precio, @fecha, @cliente, @cantidad
	while @@FETCH_STATUS = 0
	begin
		declare @factura char(14)
		set @factura =  @tipo + @sucursal + @numero
		if (dbo.compraMensual(@cliente, @fecha, @producto) + @cantidad > 100) 
		BEGIN 
            delete from item_factura where item_numero+item_sucursal+item_tipo = @numero+@SUCURSAL+@tipo
            delete from factura where fact_numero+fact_sucursal+fact_tipo = @numero+@SUCURSAL+@tipo
			while @factura = @tipo+@sucursal+@numero
				fetch next from c1 into @tipo, @sucursal, @numero, @producto, @precio, @fecha, @cliente, @cantidad
		END
		else
		begin
			insert into Item_Factura values(@tipo, @sucursal, @numero, @producto, @cantidad, @precio)
			fetch next from c1 into @tipo, @sucursal, @numero, @producto, @precio, @fecha, @cliente, @cantidad
		end
	end
	close c1
	deallocate c1
end

--USANDO AFTER
create function compraMensual(@cliente char(6), @fecha smalldatetime, @producto char(8))
returns int
as
begin
	declare @cantidad int

	select @cantidad = sum(item_cantidad) 
	from item_factura 
	join Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
	where fact_cliente = @cliente and month(Fact_fecha) = month(@fecha) and year(fact_Fecha) = year(@fecha) and item_producto = @producto
	group by item_producto

	return @cantidad

end

create trigger ej30 on Factura for insert
as
begin
	DECLARE @cliente char(6), @fecha smalldatetime
	DECLARE @sucuFact  char(4),@numFact char(8) ,@tipoFact char(1)
	DECLARE c1 cursor FOR  
	select fact_cliente,fact_fecha,fact_sucursal,fact_numero,fact_tipo from inserted 
	open c1
	FETCH NEXT FROM c1 INTO @cliente,@fecha,@sucuFact,@numFact,@tipoFact

	WHILE @@FETCH_STATUS =0
		BEGIN
			
			if (select count(*) from Item_Factura where dbo.compraMensual(@cliente, @fecha, item_producto) + item_cantidad > 100) > 0
				BEGIN 
					DELETE FROM Item_Factura WHERE item_numero+item_sucursal+item_tipo = @numFact+@sucuFact+@tipofact
					DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @numFact+@sucuFact+@tipofact
				END
			FETCH NEXT FROM c1 INTO @cliente,@anio,@mes,@sucuFact,@numFact,@tipoFact
		END 
		CLOSE c1
		deallocate c1

end


/*
31. Desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.
*/
create function cantidadEmpleados(@empleado numeric(6,0))
returns int
as
begin
	declare @cantidadEmpleados int

	select @cantidadEmpleados = count(distinct empl_codigo) from empleado where @empleado = empl_jefe

	return @cantidadEmpleados + (select isnull(sum(dbo.cantidadEmpleados(empl_codigo)),0) from empleado where empl_jefe = @empleado)
end

create procedure cambiarJefe(@jefe numeric(6))
as
begin
	
	declare @cantidadEmpleadosSobran int, @cantidadLibreNuevoJefe int, @i int

	set @i = 0

	declare @nuevoJefe numeric(6)

	set @cantidadEmpleadosSobran = dbo.cantidadEmpleados(@jefe) - 20

	select @nuevoJefe = empl_codigo from empleado where dbo.cantidadEmpleados(empl_codigo) <20 

	set @cantidadLibreNuevoJefe = 20 - dbo.cantidadEmpleados(@nuevoJefe)

	--si entran todos
	if(@cantidadLibreNuevoJefe > @cantidadEmpleadosSobran)
	begin
		while(@i < @cantidadEmpleadosSobran)
		begin
			update empleado set empl_jefe = @nuevoJefe where empl_jefe = @jefe
			set @i = @i + 1
		end
	end
	--si entra una parte
	else if(@cantidadLibreNuevoJefe > @cantidadEmpleadosSobran)
	begin
		while(@i < @cantidadLibreNuevoJefe)
		begin
			update empleado set empl_jefe = @nuevoJefe where empl_jefe = @jefe
			set @i = @i + 1
		end

		exec dbo.cambiarJefe @jefe
	end
	--no hay nadie
	else if(@nuevoJefe = null)
	begin
		declare @gerente numeric(6)
		select @gerente = empl_codigo from Empleado where empl_jefe = null

		while(@i < @cantidadEmpleadosSobran)
			begin
				update empleado set empl_jefe = @gerente where empl_jefe = @jefe
				set @i = @i + 1
			end
	end

end

create procedure ej31 
as
begin
	declare @jefe numeric (6)
	declare c1 cursor for select empl_codigo from empleado where empl_codigo in (select empl_jefe from Empleado) and empl_jefe is not null

	fetch next from c1 into @jefe
	while @@FETCH_STATUS = 0
	begin
		
		if(dbo.cantidadEmpleados(@jefe) > 20)
			exec dbo.cambiarJefe @jefe

	end

end

--FRAN
CREATE FUNCTION cantEmp ( @empJefe numeric(6))
RETURNS INT
AS 
BEGIN
		DECLARE @empleado numeric(6), @CANTIDAD INT
		DECLARE c1 CURSOR FOR
			select empl_codigo from Empleado where empl_jefe = @empJefe
		open c1
		FETCH NEXT FROM c1 INTO @empleado
		SET @CANTIDAD = 0

		WHILE @@FETCH_STATUS = 0
			BEGIN

				SET @CANTIDAD = @CANTIDAD + dbo.cantEmp(@empleado)
				FETCH NEXT FROM c1 INTO @empleado
			END
			CLOSE c1
			deallocate c1
		SET @CANTIDAD = @CANTIDAD + (select count(distinct empl_codigo) from Empleado where empl_jefe = @empJefe)
		return @CANTIDAD

END


CREATE PROCEDURE ej31 
AS BEGIN
	DECLARE @empJefe numeric(6)
	DECLARE c1 CURSOR for
		select empl_codigo from Empleado where empl_codigo in (select empl_jefe from Empleado) and dbo.cantEmp(empl_codigo)>20 and empl_jefe is not null
	open c1
	FETCH NEXT FROM c1 INTO @empJefe

	WHILE @@FETCH_STATUS = 0
		BEGIN
			if (select count(*) from Empleado where  dbo.cantEmp(empl_codigo)<20) > 0
				BEGIN
					UPDATE Empleado
					set empl_jefe = (select top 1 empl_codigo from Empleado where dbo.cantEmp(empl_codigo)<20)
					where empl_codigo = @empJefe
				END
			ELSE 
				BEGIN
				UPDATE Empleado
				set empl_jefe = (select empl_codigo from Empleado where empl_jefe is null)
				where empl_codigo = @empJefe
				END
			FETCH NEXT FROM c1 INTO @empJefe
		END
		CLOSE c1
		DEALLOCATE c1
	select

end

/*MODELO PARCIAL
Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las 
ventas de unidades promedio de los últimos 3 meses anteriores a una fecha. Se solicita que 
se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado.
*/

--MAL PQ SON RE TONTOS
IF OBJECT_ID('stock_estimado', 'U') IS NOT NULL
DROP TABLE Fact_table
GO

Create table stock_estimado
	(
	prod_codigo char(8),
	cantidad_a_reponer decimal(12,2)
	)

create function obtenerPromedio(@prod_codigo char(8), @fecha smalldatetime)
returns decimal(12,2)
as
begin
	
	declare @cantidad decimal(12,2)

	select @cantidad = sum(item_cantidad)/3
	from Item_Factura
	join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
	where fact_fecha between DATEADD(MM,-3,@fecha) and @fecha
	and item_producto=@prod_codigo

	return @cantidad
end


create procedure estimarStock(@fecha smalldatetime)
as
begin
	declare @prod_codigo char(8), @cantidadAReponer decimal(12,2)
	declare c1 cursor for select prod_codigo from producto
	
	open c1
	fetch next from c1 into @prod_codigo
	
	while @@FETCH_STATUS =0
	begin
		
		set @cantidadAReponer = dbo.obtenerPromedio(@prod_codigo,@fecha)

		insert into stock_estimado values (@prod_codigo, @cantidadAReponer)
		fetch next from c1 into @prod_codigo
	end
	close c1
	deallocate c1

end

--BIEN
alter procedure estimarStock(@fecha smalldatetime)
as
begin
	
	begin
	IF OBJECT_ID ('reponer', 'U') IS NOT NULL  
	DROP TABLE reponer; 
	CREATE TABLE reponer (
		producto char(8),
		cantidadAReponer decimal(12,2)	 
	)
	end

	insert into reponer 
		select item_producto, sum(item_cantidad) / 3
		from Item_Factura
		join Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero 
		where fact_fecha between DATEADD(month,-3,@fecha) and @fecha
		group by item_producto
end
go

--BIEN
CREATE PROCEDURE simulacro3(@fecha smalldatetime) 
AS
BEGIN
	DECLARE @fecha2 smalldatetime, @cantidad decimal(12,2)
	set @fecha2 = (SELECT DATEADD(MM, -3,@fecha))
	
	insert into LATABLA		 (select item_producto,sum(item_cantidad)/3 cant into aa from Factura join Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
							 where  fact_fecha between @fecha2 and @fecha
							 group by item_producto)

END

-------------------------------PRACTICA------------------------------------------------------
/* dada una tabla llamada TOP_CLIENTE, en la cual esta el cliente que mas unidades compro de todos los productos
en todos los tiempos se le pide que implemente el/los objetos necesarios para que la misma este simpere actualizada.
la estructura de la tabla es TOP_CLIENTE (ID_CLIENTE , CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos y 
cumplen con la condicion */

create trigger practica1 on item_factura for insert
as
begin
	
	declare @clienteMaximo char(6), @cantTotal decimal(12,2)

	select top 1 @clienteMaximo=fact_cliente, @cantTotal=sum(item_cantidad) 
		from Item_Factura 
		join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
		group by fact_cliente
		order by sum(item_cantidad) desc

		update TOP_CLIENTE set ID_CLIENTE = @clienteMaximo, CANTIDAD_TOTAL_COMPRADA = @cantTotal

end


/* Realizar un stored procedure que reciba un codigo de producto y una fecha y devuelva
la mayor cantidad de dias consecuivos a partir de esa fecha que el producto tuvo al menos
la venta de una unidad en el dia, el sistema de ventas on line esta habilitado 24-7
por lo que se deben evaluar todos los dias incluyendo domingos y feriados*/

create function huboVentas(@producto char(8), @fecha smalldatetime)
returns int
as
begin
	declare @cantidad int

	select @cantidad = sum(item_cantidad) from Item_Factura 
	join Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
	where fact_fecha = @fecha
	and item_producto = @producto

	if(@cantidad>0)
		return 1

	return 0

end


create function practica2(@producto char(8), @fecha smalldatetime)
returns int
as
begin
	
	declare @i int, @fecha2 smalldatetime
	set @i = 0
	set @fecha2 = @fecha

		while(dbo.huboVentas(@producto, @fecha2) = 1)
		begin
			set @fecha2 = DATEADD(DD, 1,@fecha2)
			set @i = @i + 1
		end

	return @i
end


/* implementar el/los objetos necesarios para implementar la siguiente restriccion en linea:
cuando se inserta en una venta un COMBO, nunca se debera guardar el producto COMBO,
sino, la descomposicion de sus componentes
actualmente se cumple*/

create trigger practica3 on item_factura instead of insert
as
begin
	declare @item_producto char (8), @sucuitem char(4),@numitem char(8) ,@tipoitem char(1), @cantidad decimal(12,2), @componente char(8), @cantidadC decimal(12,2)
	declare c1 cursor for select item_producto, item_sucursal, item_numero, item_tipo, item_cantidad from inserted where item_producto in(select comp_producto from Composicion)
	
	open c1
	fetch next from c1 into @item_producto, @sucuitem,@numitem  ,@tipoitem , @cantidad
	
	while @@FETCH_STATUS =0
	begin
		
		declare c2 cursor for select comp_componente, comp_cantidad from Composicion where comp_producto=@item_producto
		declare @precio2 decimal(12,2)
		open c2
		fetch next from c2 into @componente, @cantidadC
		while @@FETCH_STATUS =0
		begin
			select @precio2 = prod_precio from Producto where prod_codigo = @componente

			insert into Item_Factura values (@tipoitem, @sucuitem,@numitem,@componente,@cantidadC*@cantidad,@precio2)

			fetch next from c2 into @componente, @cantidadC
		end
		close c2
		deallocate c2
		fetch next from c1 into @item_producto, @sucuitem,@numitem  ,@tipoitem , @cantidad
	end
	close c1
	deallocate c1
end

