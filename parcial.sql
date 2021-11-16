/*PARCIAL*/

/*
SQL
Realizar una consulta SQL que retorne, para cada producto con más de 2 artículos 
distintos en su composición la siguiente información.

1)      Detalle del producto

2)      Rubro del producto

3)      Cantidad de veces que fue vendido -> suma de las cantidades

 El resultado deberá mostrar ordenado por la cantidad de los productos que lo componen.

 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.

*/

select prod_detalle, prod_rubro,
			count(distinct item_tipo+item_numero+item_sucursal) veces_vendido

 from producto 
 left join item_factura on item_producto = prod_codigo
 where prod_codigo in (select comp_producto
						from composicion 
						group by comp_producto 
						having count(distinct comp_componente) >2)
						--no cambia nada el distinct, pero lo puse ya que aclara mas de 2 articulos DISTINTOS
group by prod_codigo,prod_detalle, prod_rubro
order by (select sum(comp_cantidad) from composicion where comp_producto = prod_codigo) desc

--supongo que "mostrar ordenado por la cantidad de los productos que lo componen" se refiere a
--el total de productos que lo componen (osea la suma de todos), no solo productos distintos que lo componen.

/*
TSQL
Dada una tabla llamada TOP_Cliente, en la cual esta el cliente que más unidades compro de todos 
los productos en todos los tiempos se le pide que implemente el/los objetos necesarios para que 
la misma esté siempre actualizada. La estructura de la tabla es TOP_CLIENTE( ID_CLIENTE, 
CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos y cumplen con la condición.
*/

--HAGO UN TRIGGER SOBRE ITEM FACTURA, AFTER

----CREAR TABLA
CREATE TABLE TOP_CLIENTE (ID_CLIENTE char(6), CANTIDAD_TOTAL_COMPRADA int);
create trigger clienteMaximo on item_factura for insert
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

