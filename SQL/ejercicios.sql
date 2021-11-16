/*1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o igual a $ 1000 ordenado por código de cliente.*/
SELECT clie_codigo, clie_razon_social 
FROM Cliente 
WHERE (clie_limite_credito > 1000) 
ORDER BY clie_codigo

/*2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por cantidad vendida.*/
select prod_codigo, prod_detalle, sum(item_cantidad)
-- me muestra las columnas q defino, el sum(item_cantidad) no es necesario mostrar

-- select *

from producto 
join Item_Factura on prod_codigo = item_producto
-- me devuelve los productos con la info del item factura -> tengo un renglon por cada item_factura, es la tabla mas grande, marca la atomicidad

-- ahora para sacar el anio necesito joinear los item_factura con la factura
join factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero

-- filtro por el anio
WHERE year(fact_fecha) = 2012

-- para ordenar por la cantidad vendida tengo q sumar todos los item_cantidad de los q se llaman igual
group by prod_codigo, prod_detalle
order by sum(item_cantidad)

/*3. Realizar una consulta que muestre código de producto, nombre de producto y el stock total, sin importar en que deposito se encuentre, los datos deben 
ser ordenados por nombre del artículo de menor a mayor*/
select prod_codigo, prod_detalle, sum(stoc_cantidad)
from producto 
join stock on prod_codigo = stoc_producto
group by prod_codigo,prod_detalle
order by prod_detalle asc

/*4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de artículos que lo componen. Mostrar solo aquellos artículos para 
los cuales el stock promedio por depósito sea mayor a 100.*/

/*MAL CONCEPTUALMENTE -> tengo q resolverlo en un subselect
select prod_codigo, prod_detalle, count(distinct comp_componente)
-- el count(comp_producto) cuenta cuantos componentes tiene cada producto
-- el distinct hace q no se me repitan los productos por la cantidad de componentes q tiene

from Producto

-- para ver los articulos q lo componen, join con composicion
left join Composicion on prod_codigo = comp_producto
-- si no pongo left join me devuelve SOLO los prodcutos que tienen composicion
-- si un producto tiene 50 componentes, el stock lo va a sumar 50 veces. la atomicidad marca la atomicidad.

--tengo q ver la cantidad de stock de ese producto
join stock on stoc_producto = prod_codigo

group by prod_codigo, prod_detalle

--para ver el promedio por deposito, este ej solo esta bien por el avg, si fuese la suma estaria mal por lo de la composicion.
having avg(stoc_cantidad) > 100

order by 3 desc
*/

--BIEN!!!
select prod_codigo, prod_detalle, count(distinct comp_componente)
-- el count(comp_producto) cuenta cuantos componentes tiene cada producto
-- el distinct hace q no se me repitan los productos por la cantidad de componentes q tiene

from Producto

-- para ver los articulos q lo componen, join con composicion
left join composicion on prod_codigo = comp_producto
-- si no pongo left join me devuelve SOLO los prodcutos que tienen composición, yo quiero todos los productos
-- si un producto tiene 50 componentes, el stock lo va a sumar 50 veces.

group by prod_codigo, prod_detalle

-- usando el sub select esta bien conceptualmente, veo solo el producto y no cada componente como en el caso anterior
having prod_codigo in 
(select stoc_producto from stock group by stoc_producto having avg(stoc_cantidad)>100)

order by 3 desc

/*5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de stock que se realizaron para ese artículo en el año 2012 
(egresan los productos que fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.*/

select item_producto, prod_detalle, sum(item_cantidad)

from Item_Factura
-- empiezo con los productos vendidos

join Producto on prod_codigo = item_producto
--joineo con el producto, no me afecta la atomicidad, son las mismas filas

-- ahora para sacar el anio necesito joinear los item_factura con la factura
join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
-- una factura tiene muchos items -> no afecta la atomicidad

-- filtro por el anio
WHERE year(fact_fecha) = 2012

group by item_producto,prod_detalle, prod_codigo

having sum(item_cantidad) > 

--TENGO QUE REPETIR LO MISMO, PERO PARA EL 2011
(select sum(item_cantidad)
from Item_Factura join Producto on prod_codigo = item_producto join factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE item_producto = prod_codigo and year(fact_fecha) = 2011)

/*6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese rubro y stock total de ese rubro de artículos. Solo tener en 
cuenta aquellos artículos que tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/
select rubr_id,rubr_detalle, sum(stoc_cantidad)
 
from Producto

join Rubro on rubr_id = prod_rubro

join STOCK on prod_codigo = stoc_producto

where stoc_cantidad > 

(select stoc_cantidad 
from STOCK
where stoc_producto = '00000000' and stoc_deposito = '00')

group by rubr_id,rubr_detalle
order by 1

/*7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio menor precio y % de la diferencia de precios (respecto del menor Ej.: 
menor precio = 10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean stock.*/

select prod_codigo,prod_detalle,sum(stoc_cantidad) stock_total, MAX(item_precio) precio_max, MIN(item_precio) precio_min, porcentaje = ((max(item_precio) - min(item_precio)) * 100) /min(item_precio)
from Producto
join Item_Factura on prod_codigo=item_producto
join stock on prod_codigo = stoc_producto

where prod_precio > 0

group by prod_codigo,prod_detalle

having SUM(stoc_cantidad)> 0

order by 3

/*8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del artículo, stock del depósito que más stock tiene*/

select prod_detalle, max(stoc_cantidad) mayor_stock,count(distinct stoc_deposito)
from Producto
join stock on prod_codigo=stoc_producto

where stoc_cantidad>0
group by prod_codigo,prod_detalle

having count(distinct stoc_deposito) = (select count(distinct depo_codigo) from deposito)
--> la cantidad de los depósitos en los que esta es igual a la cantidad de depósitos que hay

/*9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del mismo y la cantidad de depósitos que ambos tienen asignados.*/

select empl_jefe, empl_codigo, empl_nombre, (select count(*) from DEPOSITO where depo_encargado = empl_jefe) depositos_jefe, (select count(*) from DEPOSITO where depo_encargado = empl_codigo) depositos_empleado
from Empleado
 

/*10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos vendidos en la historia. Además mostrar de esos productos, quien 
fue el cliente que mayor compra realizo.*/

select prod_codigo,prod_detalle, (
	select top 1 fact_cliente
	from Item_Factura
	join factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero
	where item_producto=prod_codigo
	group by fact_cliente
	order by sum(item_cantidad) desc
) cliente

from Producto

where prod_codigo in (
	select top 10 item_producto
	from Item_Factura
	group by item_producto
	order by sum(item_cantidad) desc
)
or prod_codigo in (
	select top 10 item_producto
	from Item_Factura
	group by item_producto
	order by sum(item_cantidad) asc
)



/*11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de productos vendidos y el monto de dichas ventas sin impuestos. 
Los datos se deberán ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga, solo se deberán mostrar las familias que tengan una 
venta superior a 20000 pesos para el año 2012.*/

select fami_detalle, count (distinct prod_codigo), sum(item_cantidad * item_precio)
from Familia

join Producto on prod_familia=fami_id
join Item_Factura on item_producto = prod_codigo
--join Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero
--si le agrego factura a items NO afecta la atomicidad, si le agrego items a la factura si cambiaria

group by fami_id,fami_detalle

having fami_id in (select prod_familia
					from Producto 
					join Item_Factura on item_producto = prod_codigo
					join Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero
					where year(fact_fecha) = 2012
					group by prod_familia
					having sum(item_precio*item_cantidad) > 20000)
order by 2 desc

/*12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe promedio pagado por el producto, cantidad de depósitos en los cuales 
hay stock del producto y stock actual del producto en todos los depósitos. Se deberán mostrar aquellos productos que hayan tenido operaciones en el año 2012 y 
los datos deberán ordenarse de mayor a menor por monto vendido del producto.*/

/*MAL!!!!!!!!!!!!!!!

select prod_detalle,count (distinct fact_cliente) cantidad_clientes, AVG(item_precio) promedio_precio, sum(item_cantidad) items_cantidad, COUNT(distinct stoc_deposito) cant_depositos, sum(stoc_cantidad) stock_total

--sum(stoc_cantidad) -> se repiten filas, HACEMOS UN SUBSELECT

from Producto

join Item_Factura on prod_codigo = item_producto
join Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero

join stock on prod_codigo = stoc_producto where stoc_cantidad > 0

group by prod_detalle, prod_codigo

having prod_codigo in (select prod_codigo from Producto 
						join Item_Factura on item_producto = prod_codigo
						join Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero
						where year(fact_fecha) = 2012
						group by prod_codigo)

--EL HAVING SIRVE PARA FILTRAR DENTRO DEL GROUP BY, LO PONEMOS EN EL WHERE PARA YA TRAER DE UNA LOS Q SE VENDIERON EN EL 2012.

order by sum(item_cantidad) desc
*/

--BIEN!!!
select prod_detalle,
prod_codigo,
       count(distinct fact_cliente) cantDifClientes,
       avg(item_precio) precioPromedio,
       count(distinct stoc_deposito) cantDepos,
       (select sum(stoc_cantidad)
       from STOCK
       where prod_codigo = stoc_producto
       group by stoc_producto)    stockTotal

from Producto 
join Item_Factura on prod_codigo = item_producto
join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
join STOCK on prod_codigo = stoc_producto  --Nose si van los que no tienen stock o si

where  prod_codigo in (
        select prod_codigo
        from Producto
        JOIN Item_Factura ON prod_codigo = item_producto
        JOIN Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
        where year(fact_fecha) = 2012
        group by prod_codigo)

        and stoc_cantidad > 0

group by prod_codigo,prod_detalle
order by sum(item_cantidad*item_precio) desc


/*13. Realizar una consulta que retorne para cada producto que posea composición nombre del producto, precio del producto, precio de la sumatoria de los precios 
por la cantidad de los productos que lo componen. Solo se deberán mostrar los productos que estén compuestos por más de 2 productos y deben ser ordenados de mayor 
a menor por cantidad de productos que lo componen*/

select p1.prod_detalle, p1.prod_precio, sum(comp_cantidad*p2.prod_precio) precioTotal

from Producto p1

join Composicion on p1.prod_codigo = comp_producto 
--p1 es la tabla de los productos "padres" (los q tienen componentes)

join Producto p2 on comp_componente = p2.prod_codigo
--p2 es otra tabla de los productos componentes "hijos" (los que componen a los padres)

group by p1.prod_detalle,p1.prod_precio, p1.prod_codigo

having count(distinct comp_componente) > 2

order by count(distinct comp_componente) desc

/*14. . Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son: 
•	Código del cliente 
•	Cantidad de veces que compro en el último año 
•	Promedio por compra en el último año 
•	Cantidad de productos diferentes que compro en el último año 
•	Monto de la mayor compra que realizo en el último año 
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en el último año. No se deberán visualizar NULLs en ninguna columna*/

/*MAL
select fact_cliente, 
		count(*) cantidadCompras, 
		avg(fact_total) promedioCompra, 
		count(distinct item_producto) productosDiferentes, 
		MAX(fact_total) mayorCompra

from Factura

join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo + fact_sucursal + fact_numero

where year(fact_fecha) = (select max(year(fact_fecha)) from Factura)
--USO LAS FACTURAS DEL ULTIMO ANIO

group by fact_cliente

order by 2
*/

--BIEN
select fact_cliente,
       count (distinct fact_numero+fact_tipo+fact_sucursal) cantidad,
       avg(fact_total) promedio,
       count(distinct item_producto) cantProductos,
       max(fact_total) mayorCompra
from Factura
JOIN Item_Factura ON item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
left join Cliente on fact_cliente = clie_codigo
where year(fact_fecha) = (select max(year(fact_fecha)) from factura)
group by fact_cliente
order by 2

/*
15. Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
*/

select p1.prod_codigo, p1.prod_detalle,p2.prod_codigo, p2.prod_detalle, count(*) veces

from item_factura i1 join producto p1 on i1.item_producto = p1.prod_codigo ,
         item_factura i2 join producto p2 on i2.item_producto = p2.prod_codigo

where i1.item_tipo +i1.item_sucursal+i1.item_numero = i2.item_tipo +i2.item_sucursal+i2.item_numero
        and p1.prod_detalle > p2.prod_detalle
		--para q no esten repetidos
group by p1.prod_codigo, p1.prod_detalle,p2.prod_codigo, p2.prod_detalle
having count(*) > 500

/* 16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente. */

select clie_razon_social, sum(item_cantidad) uniTotales, (select top 1 item_producto
															from Item_Factura
															join factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
															where fact_cliente = clie_codigo
															group by item_producto
															order by sum(item_cantidad) desc, item_producto) mayorProd

from Item_Factura
join factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
join cliente on fact_cliente = clie_codigo

--filtro los clientes cuyas ventas son inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
where year(fact_fecha) = 2012 
and
clie_codigo in (select fact_cliente
						from Factura
						group by fact_cliente
						having count(fact_cliente) < ((select top 1 avg(item_cantidad) cantTotal
														from Item_Factura
														join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
														where year(fact_fecha) = 2012
														group by item_producto
														order by sum(item_cantidad) desc) /3)) --promedio de ventas del producto que mas se vendio

--NO ENTIENDO EL COUNT(FACT_CLIENTE) => cuenta la cantidad de commpras que hizo, las ventas de los  clientes no se evaluan sumando la cantidad de cada producto de la factura
--NO TIENE SENTIDO

group by clie_razon_social, clie_codigo, clie_domicilio
order by clie_domicilio asc

/*
17. Escriba una consulta que retorne una estadística de ventas por año y mes para cada
producto.
La consulta debe retornar:
	PERIODO: Año y mes de la estadística con el formato YYYYMM
	PROD: Código de producto
	DETALLE: Detalle del producto
	CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
	VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo
	pero del año anterior
	CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el
	periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.
*/

--LTRIM Y RTRIM ES PARA SACAR LOS ESPACIOS
--SI NO PUEDE SER: rtrim(ltrim(str(year(fact_fecha)))) + right('0' + rtrim(ltrim(str(month(fact_fecha)))), 2)
select CONCAT(YEAR(F1.fact_fecha), RIGHT('0' + RTRIM(MONTH(F1.fact_fecha)), 2))  Periodo,
       prod_codigo ,
       prod_detalle detalle,
       isnull(sum(item_cantidad),0) CANTIDAD_VENDIDA,
       isnull((select sum(item_cantidad)
        from Item_Factura
        join Factura f2 on item_numero + item_tipo + item_sucursal = f2.fact_numero + f2.fact_tipo + f2.fact_sucursal 
        where year(f2.fact_fecha) = year(f1.fact_fecha) - 1
        and month(f1.fact_fecha) = month(f2.fact_fecha)),0) ventas_anio_ant,
        count(*) cant_facturas
from Item_Factura i1
join Factura f1 on i1.item_numero + i1.item_tipo + i1.item_sucursal = f1.fact_numero + f1.fact_tipo + f1.fact_sucursal 
join Producto on item_producto = prod_codigo
group by  prod_codigo, prod_detalle, YEAR(F1.fact_fecha), MONTH(F1.fact_fecha)
ORDER BY 1, 2

/*
18. Escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.
*/
/*MEH, TIENE SUBSELECT Y NO LE GUSTA A KIKE
select rubr_detalle DETALLE_RUBRO,  isnull((select sum(item_precio*item_cantidad)
										from Producto
										Join Item_Factura on item_producto = prod_codigo
										where prod_rubro = rubr_id),0) VENTAS
from Producto
join Rubro on prod_rubro=rubr_id
group by rubr_detalle, rubr_id
*/

-- SIN EL SUBSELECT :D
select rubr_detalle,
       isnull(sum(item_precio*item_cantidad),0) VENTAS,
	   
       isnull((select top 1 p1.prod_codigo
        from Producto p1
        join Item_Factura i1 on p1.prod_codigo = i1.item_producto 
        where p1.prod_rubro = rubr_id
        group by p1.prod_codigo
        order by sum(i1.item_cantidad) desc),'-') PROD1,

        isnull((select top 1 p2.prod_codigo
        from Producto p2
		join Item_Factura i2 on p2.prod_codigo = i2.item_producto 
        where p2.prod_rubro = rubr_id
        and
		--BUSCO UN PRODCUTO QUE NO TENGA EL PROD CODIGO DEL MAS VENDIDO (LO DE ARRIBA)
        p2.prod_codigo not in
            (select top 1 p1.prod_codigo
			from Producto p1
			join Item_Factura i1 on p1.prod_codigo = i1.item_producto 
			where p1.prod_rubro = rubr_id
			group by p1.prod_codigo
			order by sum(i1.item_cantidad) desc)
		group by p2.prod_codigo
        order by sum(i2.item_cantidad) desc),'-') PROD2,

		isnull((select top 1 fact_cliente
		from Item_Factura
		join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		join Producto on item_producto = prod_codigo
		where prod_rubro = rubr_id
		and 
		fact_fecha > (SELECT DATEADD(DAY, -30, MAX(fact_fecha)) FROM Factura)
		group by fact_cliente
		order by sum(item_cantidad) desc),'no hay cliente') CLIENTE
from Rubro
    join producto on prod_rubro = rubr_id
    join item_factura on item_producto = prod_codigo
group by rubr_detalle,rubr_id
order by count(distinct item_producto)

/*
19.  En virtud de una recategorizacion de productos referida a la familia de los mismos se 
solicita que desarrolle una consulta sql que retorne para todos los productos:

 Codigo de producto
 Detalle del producto
 Codigo de la familia del producto
 Detalle de la familia actual del producto
 Codigo de la familia sugerido para el producto
 Detalla de la familia sugerido para el producto

La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo 
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor 
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea 
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/

/*MAL INTERPRETADO
select prod_codigo, 
		prod_detalle, 
		f1.fami_id, 
		f1.fami_detalle, 
		(SELECT TOP 1 prod_familia
			FROM Producto
			WHERE left(prod_detalle, 5) = left(p1.prod_detalle, 5)
			and
			f1.fami_id != prod_familia
			GROUP BY prod_familia
			ORDER BY COUNT(*) DESC, prod_familia) flia_sugerida,
		(select fami_detalle
			from Familia
			where fami_id = (SELECT TOP 1 prod_familia
			FROM Producto
			WHERE left(prod_detalle, 5) = left(p1.prod_detalle, 5)
			and
			f1.fami_id != prod_familia
			GROUP BY prod_familia
			ORDER BY COUNT(*) DESC, prod_familia ))flia_sugerida_detalle

from producto p1
	join familia f1 on prod_familia = f1.fami_id

where f1.fami_id != (SELECT TOP 1 prod_familia
		FROM Producto
		WHERE left(prod_detalle, 5) = left(p1.prod_detalle, 5)
		GROUP BY prod_familia
		ORDER BY COUNT(*) DESC, prod_familia) 
		--PARA QUE NO MUESTRE LOS REPETIDOS

group by f1.fami_id,  f1.fami_detalle
order by prod_detalle
*/

--BIEN
SELECT prod_codigo,
  prod_detalle,
  fami_id,
  fami_detalle,

  (SELECT top 1 fami_id from Familia
   where LEFT(fami_detalle,5)=LEFT(prod_detalle,5)  
   group by fami_id
   order by COUNT(*)desc , fami_id asc) fami_sugerida,

  (SELECT top 1 fami_detalle from Familia 
   where LEFT(fami_detalle,5)=LEFT(prod_detalle,5)  
   group by fami_id,fami_detalle
   order by COUNT(*)desc , fami_id asc) fami_sugerida_detalle

FROM Producto join Familia on (prod_familia = fami_id)
where fami_detalle <>(SELECT top 1 fami_detalle from Familia
						where LEFT(fami_detalle,5)=LEFT(prod_detalle,5)  
						group by fami_detalle,fami_id
						order by COUNT(*)desc , fami_id asc)


/*
20.  Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje 
2012. 
El puntaje de cada empleado se calculara de la siguiente manera: para los que 
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas 
que superen los 100 pesos que haya vendido en el año, para los que tengan menos de 50
facturas en el año el calculo del puntaje sera el 50% de cantidad de facturas realizadas 
por sus subordinados directos en dicho año.
*/
/*
select top 3
	empl_codigo,
	empl_nombre,
	empl_apellido,
	year(empl_ingreso) anio_ingreso,
	case
		when((select count(distinct fact_numero) from factura where empl_codigo = fact_vendedor and year(fact_fecha) = 2011) >= 50)
		then(select count(*) from Factura where fact_total > 100 and empl_codigo = fact_vendedor and year(fact_fecha)= 2011)
		else(select count(*) * 0.5 from Factura where fact_vendedor in (select empl_codigo from Empleado where empl_jefe = empl_codigo) and year(fact_fecha)=2011)
		-- dame todas las faturas del 2011 y que tengan como fact vendedor el codigo de los subordinados de mi empleado
	END puntaje_2011,
	case
		when((select count(distinct fact_numero) from factura where empl_codigo = fact_vendedor and year(fact_fecha) = 2011) >= 50)
		then(select count(*) from Factura where fact_total > 100 and empl_codigo = fact_vendedor and year(fact_fecha)= 2011)
		else(select count(*) * 0.5 from Factura where fact_vendedor in (select empl_codigo from Empleado where empl_jefe = empl_codigo) and year(fact_fecha)=2011)
		-- dame todas las faturas del 2012 y que tengan como fact vendedor el codigo de los subordinados de mi empleado
	END puntaje_2012

from Empleado
order by 6 desc
*/
--NOSE PQ EL DE ARRIBA SE CALCULA MAL SHORAR PERO WENO ES LO MISMO
select top 3
	empl_codigo,
	empl_nombre,
	empl_apellido,
	year(empl_ingreso) anioIngreso,
	case
		when((select count(distinct (fact_numero+fact_tipo+fact_sucursal)) from Factura where empl_codigo = fact_vendedor and year(fact_fecha) = 2011)>=50)
		then(select count(*)
			 from factura
			 where fact_total > 100
			 and empl_codigo = fact_vendedor
			 and year(fact_fecha) = 2011)
		else(select count(*) * 0.5
			 from factura
			 where fact_vendedor in (select empl_codigo from Empleado where empl_jefe = empl_codigo)
			 and
			 year(fact_fecha) = 2011)
		END Puntaje_2011,

	case
		when((select count(fact_numero+fact_tipo+fact_sucursal) from Factura where empl_codigo = fact_vendedor and year(fact_fecha) = 2012)>=50)
		then(select count(*)
			 from factura
			 where fact_total > 100
			 and empl_codigo = fact_vendedor
			 and year(fact_fecha) = 2012)
		else(select count(*) * 0.5
			 from factura
			 where fact_vendedor in (select empl_codigo from Empleado where empl_jefe = empl_codigo)
			 and
			 year(fact_fecha) = 2012)
		END Puntaje_2012

from Empleado
order by 6 desc

/*
21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al 
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta 
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se 
considera que una factura es incorrecta cuando la diferencia entre el total de la factura 
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de 
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar 
son:
	 Año
	 Clientes a los que se les facturo mal en ese año
	 Facturas mal realizadas en ese año
*/

select year(fact_fecha) anio_factura, count(distinct fact_cliente) clientes_mal_facturados, count(*) facturas_incorrectas
from Factura
where (fact_total - fact_total_impuestos) > 1 + (select sum(item_cantidad*item_precio) 
												 from Item_Factura 
												 where item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal)
group by year(fact_fecha)

/*
22. Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por 
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1 
por cada trimestre).
Se deben mostrar 4 columnas:
	 Detalle del rubro
	 Numero de trimestre del año (1 a 4)
	 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al 
	menos un producto del rubro
	 Cantidad de productos diferentes del rubro vendidos en el trimestre 
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada 
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas 
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta 
estadistica.
*/

select rubr_detalle,
		case
			when month(fact_fecha) = 1 or month(fact_fecha) = 2 or month(fact_fecha) = 3
			then 1
			when month(fact_fecha) = 4 or month(fact_fecha) = 5 or month(fact_fecha) = 6
			then 2
			when month(fact_fecha) = 7 or month(fact_fecha) = 8 or month(fact_fecha) = 9
			then 3
			when month(fact_fecha) = 10 or month(fact_fecha) = 11 or month(fact_fecha) = 12
			then 4
		END numero_trimestre,
		count(distinct fact_numero + fact_tipo + fact_sucursal) cantidad_facturas,
		count(distinct item_producto) cant_productos
from Rubro
join Producto on prod_rubro = rubr_id
join Item_Factura on prod_codigo = item_producto
join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
where prod_codigo not in (select comp_producto from Composicion)

--AGRUPO POR TRIMESTRE
group by rubr_detalle,
		case
			when month(fact_fecha) = 1 or month(fact_fecha) = 2 or month(fact_fecha) = 3
			then 1
			when month(fact_fecha) = 4 or month(fact_fecha) = 5 or month(fact_fecha) = 6
			then 2
			when month(fact_fecha) = 7 or month(fact_fecha) = 8 or month(fact_fecha) = 9
			then 3
			when month(fact_fecha) = 10 or month(fact_fecha) = 11 or month(fact_fecha) = 12
			then 4
		END 

having count(distinct fact_numero + fact_tipo + fact_sucursal) >100
order by 1, 2 desc

--> DATEPART DEVUELVE EL TRIMESTRE
select rubr_detalle,
	   DATEPART(QUARTER,fact_fecha) Trimestre,
	   count(distinct  fact_numero + fact_tipo + fact_sucursal) facturas,
	   count(distinct item_producto) cantProd
from Rubro
join Producto on prod_rubro = rubr_id
join Item_Factura on prod_codigo = item_producto
join factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
where prod_codigo not in (select comp_producto from Composicion)
group by rubr_detalle,DATEPART(QUARTER,fact_fecha)
having count(distinct fact_numero + fact_tipo + fact_sucursal) > 100
order by 1, 2 desc

/*
23.  Realizar una consulta SQL que para cada año muestre :
	 Año
	 El producto con composición más vendido para ese año.
	 Cantidad de productos que componen directamente al producto más vendido
	 La cantidad de facturas en las cuales aparece ese producto.
	 El código de cliente que más compro ese producto.
	 El porcentaje que representa la venta de ese producto respecto al total de venta 
	  del año.
El resultado deberá ser ordenado por el total vendido por año en forma descendente.
*/

/*TO' MAL
select year(f1.fact_fecha) Anio,
	   comp_producto prodMasVendido,
	   count(distinct comp_cantidad) cant_productos,
	   count(distinct fact_numero + fact_tipo + fact_sucursal) cant_facturas,
	   (select top 1 fact_cliente
	    from Factura
		join Item_Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		where item_producto = comp_producto
		and year(f1.fact_fecha) = year(fact_fecha)
		group by fact_cliente
		order by sum(item_cantidad) desc) mayor_cliente,
		(sum(item_cantidad)*100/(select sum(item_cantidad) 
								 from Item_Factura
								 join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
								 where year(f1.fact_fecha) = year(fact_fecha))) porcentaje
from Composicion
join Item_Factura on item_producto = comp_producto
join Factura f1 on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
where comp_producto in (select top 1 item_producto
						   from Item_Factura 
						   join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
						   join Composicion on item_producto = Comp_producto
						   where year(fact_fecha) = year(f1.fact_fecha)
						   group by item_producto 
						   order by sum(item_cantidad) desc) 
group by year(f1.fact_fecha), comp_producto
order by sum(item_cantidad) desc
*/

select year(f1.fact_fecha) Anio,

	   (select top 1 item_producto
		from Item_Factura 
		join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		join Composicion on item_producto = Comp_producto
		where year(fact_fecha) = year(f1.fact_fecha)
		group by item_producto 
		order by sum(item_cantidad) desc)  prodMasVendido,

	   (select top 1 count(distinct comp_cantidad)
		from Item_Factura 
		join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		join Composicion on item_producto = Comp_producto
		where year(fact_fecha) = year(f1.fact_fecha)
		group by item_producto 
		order by sum(item_cantidad) desc) cant_productos,

	   count(distinct fact_numero + fact_tipo + fact_sucursal) cant_facturas,

	   (select top 1 fact_cliente
	    from Factura
		join Item_Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		where item_producto in (select top 1 item_producto
								from Item_Factura 
								join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
								join Composicion on item_producto = Comp_producto
								where year(fact_fecha) = year(f1.fact_fecha)
								group by item_producto 
								order by sum(item_cantidad) desc)
		and year(f1.fact_fecha) = year(fact_fecha)
		group by fact_cliente
		order by sum(item_cantidad) desc) mayor_cliente,

		((select top 1 sum(item_cantidad)
		from Item_Factura 
		join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
		join Composicion on item_producto = Comp_producto
		where year(fact_fecha) = year(f1.fact_fecha)
		group by item_producto 
		order by sum(item_cantidad) desc)*100/(select sum(item_cantidad) 
												 from Item_Factura
												 join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
												 where year(f1.fact_fecha) = year(fact_fecha))) porcentaje

from Item_Factura
join Factura f1 on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
group by year(f1.fact_fecha)
order by sum(item_cantidad) desc

/*
24.  Escriba una consulta que considerando solamente las facturas correspondientes a los 
dos vendedores con mayores comisiones, retorne los productos con composición 
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
	 Código de Producto
	 Nombre del Producto
	 Unidades facturadas
El resultado deberá ser ordenado por las unidades facturadas descendente.
*/

select prod_codigo, 
	   prod_detalle,
	   count(item_producto) vecesFacturado,
	   sum(item_cantidad) unidadesFacturadas

from Producto
join Item_Factura on item_producto= prod_codigo
join factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal

where fact_vendedor in(select top 2 empl_codigo
						from Empleado
						order by empl_comision desc)
and 
prod_codigo in(select comp_producto from Composicion)

group by Prod_codigo, prod_detalle
having count(item_producto) >5
order by 4 desc

/*
25. Realizar una consulta SQL que para cada año y familia muestre :
		a. Año
		b. El código de la familia más vendida en ese año.
		c. Cantidad de Rubros que componen esa familia.
		d. Cantidad de productos que componen directamente al producto más vendido de 
		   esa familia.
 		e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa 
           familia.
		f. El código de cliente que más compro productos de esa familia.
		g. El porcentaje que representa la venta de esa familia respecto al total de venta 
           del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma 
descendente.

*/

select year(f1.fact_fecha) anio,
		 fami_id familia_mas_vendida,
		 count(distinct prod_rubro) cant_rubros,

		 isnull((select top 1 count(comp_cantidad)
		  from Composicion
		  join Producto on comp_producto = prod_codigo
		  join Item_Factura on item_producto = prod_codigo
		  join Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		  where fami_id = prod_familia
		  and 
		  year(f1.fact_fecha) = year(fact_fecha)
		  group by prod_codigo
		  order by sum(item_cantidad) desc),1) comps_mas_vendido,

		  count(distinct fact_numero + fact_tipo + fact_sucursal) cant_facturas,

		  (select top 1 fact_cliente
		   from Producto 
		   join Item_Factura on item_producto = prod_codigo
		   join Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		   where prod_familia=fami_id
		   and
		   year(f1.fact_fecha) = year(fact_fecha)
		   group by fact_cliente
		   order by sum(item_cantidad) desc) mayor_cliente,

		   ((sum(item_cantidad*item_precio)*100)/((select sum(item_cantidad * item_precio)
													from Factura
													join Item_Factura on fact_numero = item_numero and fact_sucursal = item_sucursal and fact_tipo = item_tipo
													join Producto on prod_codigo = item_producto
													where year(fact_fecha) = year(f1.fact_fecha)
													))) porcentaje

from familia
join Producto on prod_familia = fami_id
join Item_Factura on prod_codigo = item_producto
join factura f1 ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo

where fami_id in (select top 1 prod_familia
					from Producto
					join Item_Factura on item_producto = prod_codigo
					--join Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
					--where year(f1.fact_fecha) = year(fact_fecha)
					group by prod_familia
					order by sum(item_cantidad) desc)


group by year(f1.fact_fecha), fami_id
order by sum(item_cantidad*item_precio) desc,2

/*
26.  Escriba una consulta sql que retorne un ranking de empleados devolviendo las 
siguientes columnas:
	 Empleado
	 Depósitos que tiene a cargo
	 Monto total facturado en el año corriente
	 Codigo de Cliente al que mas le vendió
	 Producto más vendido
	 Porcentaje de la venta de ese empleado sobre el total vendido ese año.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.
*/

select empl_codigo, 
		count(distinct depo_codigo) depositos_totales,

		(select sum(fact_total) 
		 from factura 
		 where year(fact_fecha) =(select max(year(fact_fecha))from factura)
		 and fact_vendedor=empl_codigo) monto_total,

		(select top 1 fact_cliente
		 from factura
		 where fact_vendedor = empl_codigo
		 group by fact_cliente
		 order by sum(fact_total) desc) mayor_cliente,

		 (select top 1 Item_producto
		  from Item_Factura
		  join Factura on fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		  where fact_vendedor = empl_codigo
		  group by item_producto
		  order by sum(item_cantidad) desc) mayor_producto,

		  (((select sum(fact_total) 
			 from factura 
			 where year(fact_fecha) =(select max(year(fact_fecha))from factura)
			 and fact_vendedor=empl_codigo)*100)/((select sum(fact_total)
													from Factura
													where year(fact_fecha) = (select max(year(fact_fecha)) from factura)
													))) porcentaje
from deposito
--RIGHT JOIN AGREGA LOS EMPLEADOS Q NO TIENEN DEPOSITOS
right join Empleado on depo_encargado = empl_codigo
--uso left join para que me muestre los empleados que no facturaron. 
left join Factura on fact_vendedor = empl_codigo

where year(fact_fecha) = (select max(year(fact_fecha)) from factura)

group by empl_codigo
order by 3 desc

/*
27. Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
  Año
  Codigo de envase
  Detalle del envase
  Cantidad de productos que tienen ese envase
  Cantidad de productos facturados de ese envase
  Producto mas vendido de ese envase
  Monto total de venta de ese envase en ese año
  Porcentaje de la venta de ese envase respecto al total vendido de ese año
Los datos deberan ser ordenados por año y dentro del año por el envase con más
facturación de mayor a menor
*/

select year(f1.fact_fecha) anio, 
	   enva_codigo, 
	   enva_detalle,

	   (select count(distinct prod_codigo) 
	    from Producto
		where prod_envase = enva_codigo) cant_prods_envase,

		count(distinct item_producto) cant_prods_facturados,

		(select top 1 item_producto
		 from Producto
		 join Item_Factura on item_producto=prod_codigo
		 join Factura on fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
		 where prod_envase=enva_codigo
		 and
		 year(f1.fact_fecha) = year(fact_fecha)
		 group by item_producto
		 order by sum(item_cantidad) desc) prod_mas_vendido,

		 sum(item_cantidad*item_precio) monto_total,

		 ((sum(item_cantidad*item_precio)*100)/((select sum(fact_total)
												from Factura
												where year(f1.fact_fecha) = year(fact_fecha)))) porcentaje

from Envases
join Producto on prod_envase=enva_codigo
join Item_Factura on prod_codigo = item_producto
join Factura f1 on f1.fact_numero = item_numero AND f1.fact_sucursal = item_sucursal AND f1.fact_tipo = item_tipo
group by year(fact_fecha), enva_codigo, enva_detalle
order by 1, 7 desc

/*
28.  Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las 
siguientes columnas:
	 Año.
	 Codigo de Vendedor
	 Detalle del Vendedor
	 Cantidad de facturas que realizó en ese año
	 Cantidad de clientes a los cuales les vendió en ese año.
	 Cantidad de productos facturados con composición en ese año
	 Cantidad de productos facturados sin composicion en ese año.
	 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya 
vendido mas productos diferentes de mayor a menor
*/

select year(f1.fact_fecha) anio, 
		f1.fact_vendedor,
		empl_apellido,
		count(distinct f1.fact_numero + f1.fact_tipo + f1.fact_sucursal) cant_facturas,
		count(distinct fact_cliente) cant_clientes,

		isnull((select count(distinct item_producto)
		from Item_Factura
		join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
		where item_producto in (select comp_producto from Composicion)
		and 
		year(f1.fact_fecha) = year(fact_fecha)
		and
		f1.fact_vendedor = fact_vendedor),0) prods_comp,

		isnull((select count(distinct item_producto)
		from Item_Factura
		join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
		where item_producto not in (select comp_producto from Composicion)
		and 
		year(f1.fact_fecha) = year(fact_fecha)
		and
		f1.fact_vendedor = fact_vendedor),0) prods_no_comp,

		sum(f1.fact_total) monto_total

from factura f1 
--RIGHT JOIN INCLUYE LOS Q ESTAN EN NULL DEL EMPLEADO
join Empleado on fact_vendedor = empl_codigo
group by year(f1.fact_fecha), fact_vendedor,empl_apellido
order by 1, (select count(distinct item_producto)
			 from Item_Factura
			 join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
			 where year(f1.fact_fecha) = year(fact_fecha)
			 and
			 f1.fact_vendedor = fact_vendedor) desc

/*
29.  Se solicita que realice una estadística de venta por producto para el año 2011, solo para 
los productos que pertenezcan a las familias que tengan más de 20 productos asignados 
a ellas, la cual deberá devolver las siguientes columnas:
	a. Código de producto
	b. Descripción del producto
	c. Cantidad vendida
	d. Cantidad de facturas en la que esta ese producto
	e. Monto total facturado de ese producto
Solo se deberá mostrar un producto por fila en función a los considerandos establecidos 
antes. El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.
*/

select prod_codigo,
       prod_detalle,
       sum(item_cantidad) CantVendida,
       count(distinct fact_tipo+fact_numero+fact_sucursal) CantFacturas,
       sum(item_cantidad*item_precio) MontoTotal
from Producto
join Item_Factura on item_producto = prod_codigo
join Factura on item_numero + item_tipo + item_sucursal = fact_numero + fact_tipo + fact_sucursal
where year(fact_fecha) = 2011
and
prod_familia in (select fami_id
                       from Familia
                       join Producto on fami_id = prod_familia
                       group by fami_id
                       having count(distinct prod_codigo) >20)
group by prod_codigo,prod_detalle
order by 3 desc

/*
30. Se desea obtener una estadistica de ventas del año 2012, para los empleados que sean 
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la 
consulta que retorne las siguientes columnas:
	 Nombre del Jefe
	 Cantidad de empleados a cargo
	 Monto total vendido de los empleados a cargo
	 Cantidad de facturas realizadas por los empleados a cargo
	 Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese 
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se 
deben mostrarse los jefes cuyos subordinados hayan realizado más de 10 facturas.

*/
/* MAL - MUCHOS SUBSELECTS
select empl_nombre,
		(select count(distinct empl_codigo)
		 from Empleado
		 where empl_jefe = e1.empl_codigo) cant_empleados,

		 (select sum(fact_total)
		  from Factura
		  where fact_vendedor in (select empl_codigo
								  from Empleado
								  where empl_jefe = e1.empl_codigo)) monto_empleados,

		  (select count(distinct fact_numero + fact_tipo + fact_sucursal)
		  from Factura
		  where fact_vendedor in (select empl_codigo
								  from Empleado
								  where empl_jefe = e1.empl_codigo)) facts_empleados,

		  (select top 1 empl_nombre
		   from Factura
		   join empleado on empl_codigo=fact_vendedor
		   where fact_vendedor in (select empl_codigo
								  from Empleado
								  where empl_jefe = e1.empl_codigo)
		   group by empl_nombre
		   order by sum(fact_total) desc) mayor_subdito

from factura
join empleado e1 on fact_vendedor=e1.empl_codigo
where year(fact_fecha) = 2012
and
exists (select empl_codigo
		 from Empleado
		 where empl_jefe = e1.empl_codigo)
group by e1.empl_nombre, e1.empl_codigo

*/

--BIEN
select J.empl_nombre,
		count(distinct e.empl_codigo) cant_empleados,

		sum(fact_total) monto_empleados,

		count(distinct fact_numero + fact_tipo + fact_sucursal) facts_empleados,

		  (select top 1 empl_nombre
		   from Factura
		   join empleado on empl_codigo=fact_vendedor
		   where fact_vendedor in (select empl_codigo
								  from Empleado
								  where empl_jefe = j.empl_codigo)
		   group by empl_nombre
		   order by sum(fact_total) desc) mayor_subdito

from empleado J
--ME ASEGURO QUE TENGA EMPLEADOS
join empleado E on E.empl_jefe=J.empl_codigo
join Factura on e.empl_codigo = fact_vendedor
where year(fact_fecha) = 2012
group by J.empl_nombre, J.empl_codigo

having count(distinct fact_numero + fact_tipo + fact_sucursal) > 10

order by 3 desc

/*
31. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las 
siguientes columnas:
	 Año.
	 Codigo de Vendedor
	 Detalle del Vendedor
	 Cantidad de facturas que realizó en ese año
	 Cantidad de clientes a los cuales les vendió en ese año.
	 Cantidad de productos facturados con composición en ese año
	 Cantidad de productos facturados sin composicion en ese año.
	 Monto total vendido por ese vendedor en ese año
Los datos deberan ser ordenados por año y dentro del año por el vendedor que haya 
vendido mas productos diferentes de mayor a menor.
*/

-- YA LO HICIMOS -> 28

/*
32. Se desea conocer las familias que sus productos se facturaron juntos en las mismas 
facturas para ello se solicita que escriba una consulta sql que retorne los pares de 
familias que tienen productos que se facturaron juntos. Para ellos deberá devolver las 
siguientes columnas:
	 Código de familia 
	 Detalle de familia
	 Código de familia
	 Detalle de familia 
	 Cantidad de facturas
	 Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias 
que se vendieron juntas más de 10 veces.
*/

select f1.fami_id fami1,
		f1.fami_detalle detalle1,
		f2.fami_id fami2,
		f2.fami_detalle detalle2,
		count(distinct i2.item_numero+ i2.item_tipo+ i2.item_sucursal),
		sum(i1.item_cantidad*i1.item_precio) + sum(i2.item_cantidad*i2.item_precio)
from familia f1
	join Producto p1 on f1.fami_id=p1.prod_familia
	join Item_Factura i1 on i1.item_producto = p1.prod_codigo,
familia f2
	join Producto p2 on f2.fami_id=p2.prod_familia
	join Item_Factura i2 on i2.item_producto = p2.prod_codigo

where f1.fami_id < f2.fami_id
and
i1.item_numero+ i1.item_tipo+ i1.item_sucursal = i2.item_numero+ i2.item_tipo+ i2.item_sucursal

group by f1.fami_detalle, f1.fami_id, f2.fami_id, f2.fami_detalle
having count(distinct i2.item_numero+ i2.item_tipo+ i2.item_sucursal) >10
order by 6

/*
33. Se requiere obtener una estadística de venta de productos que sean componentes. Para 
ello se solicita que realiza la siguiente consulta que retorne la venta de los 
componentes del producto más vendido del año 2012. Se deberá mostrar:
	a. Código de producto
	b. Nombre del producto
	c. Cantidad de unidades vendidas
	d. Cantidad de facturas en la cual se facturo
	e. Precio promedio facturado de ese producto.
	f. Total facturado para ese producto
El resultado deberá ser ordenado por el total vendido por producto para el año 2012
*/


select prod_codigo,
		prod_detalle,
		isnull(sum(item_cantidad),0) cantVendidas,
		count(distinct fact_numero + fact_tipo + fact_sucursal) cantFacturas,
		isnull(avg(item_precio),0) precioPromedio,
		isnull(sum(item_precio*item_cantidad),0) totalFacturados
from Producto
left join Item_Factura on prod_codigo=item_producto
left join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
where prod_codigo = (select top 1 item_producto
						from Item_Factura
						join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
						where item_producto in (select comp_producto from Composicion)
						and year(fact_fecha) = 2012
						group by item_producto
						order by sum(item_cantidad) desc)
and
prod_codigo in (select comp_producto from Composicion)
group by prod_codigo,prod_detalle
order by 6 desc

/*
34. Escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal 
facturadas por cada mes del año 2011 Se considera que una factura es incorrecta cuando 
en la misma factura se factutan productos de dos rubros diferentes. Si no hay facturas 
mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
	1- Codigo de Rubro
	2- Mes
	3- Cantidad de facturas mal realizadas.
*/
select prod_rubro,
       month(fact_Fecha) Mes,
       CASE WHEN (select count(distinct prod_rubro)
                 from Producto
                 join Item_Factura on item_producto = prod_codigo
                 where i1.item_tipo + i1.item_sucursal +i1.item_numero  = item_tipo + item_sucursal+item_numero 
                 group by item_tipo+item_sucursal+item_numero )>1
            then (select count(distinct prod_rubro)
                 from Producto
                 join Item_Factura on item_producto = prod_codigo
                 where i1.item_tipo + i1.item_sucursal +i1.item_numero  = item_tipo + item_sucursal+item_numero 
                 group by item_tipo+item_sucursal+item_numero )
            else 0
            end as CantDeFacturas                
from Producto 
join Item_Factura i1 on i1.item_producto = prod_codigo
--join Factura on i1.item_tipo + i1.item_sucursal + i1.item_numero  = fact_tipo + fact_sucursal + fact_numero  
join factura on fact_tipo = i1.item_tipo and fact_sucursal = I1.item_sucursal and fact_numero = I1.item_numero --con esta da igual pero mas rapido
where year(fact_fecha) = 2011
group by prod_rubro,month(fact_Fecha),  i1.item_tipo + i1.item_sucursal + i1.item_numero
order by 3


/*
35. Se requiere realizar una estadística de ventas por año y producto, para ello se solicita 
que escriba una consulta sql que retorne las siguientes columnas:
	 Año
	 Codigo de producto
	 Detalle del producto
	 Cantidad de facturas emitidas a ese producto ese año
	 Cantidad de vendedores diferentes que compraron ese producto ese año.
	 Cantidad de productos a los cuales compone ese producto, si no compone a ninguno 
	  se debera retornar 0.
	 Porcentaje de la venta de ese producto respecto a la venta total de ese año.
Los datos deberan ser ordenados por año y por producto con mayor cantidad vendida.
*/

select year(f1.fact_fecha) anio,
		prod_codigo,
		prod_detalle, 
		count(distinct f1.fact_numero + f1.fact_tipo + f1.fact_sucursal),
		count(distinct f1.fact_vendedor) vendedores,
		isnull((select count(distinct comp_producto)
				from composicion
				where comp_producto = prod_codigo),0) cuantosCompone,
		(sum(item_precio*item_cantidad)*100 / (select sum(fact_total)
												from Factura
												where year(fact_fecha) = year(f1.fact_fecha)))
from Factura f1
join Item_Factura on f1.fact_numero + f1.fact_tipo + f1.fact_sucursal = item_numero+ item_tipo+ item_sucursal
join Producto on item_producto = prod_codigo
--left join Composicion on comp_componente = prod_codigo

group by year(f1.fact_fecha), prod_codigo,prod_detalle
order by 1, sum(item_cantidad) desc



/*MODELO PARCIAL
Se necesita saber que productos no han sido vendidos durante el año 2012 pero que sí tuvieron ventas en año anteriores. De esos productos mostrar:

Código de producto
Nombre de Producto
Un string que diga si es compuesto o no.
 El resultado deberá ser ordenado por cantidad vendida en años anteriores.

NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/
--MAL
select prod_codigo, prod_detalle, 
	case when(prod_codigo in (select comp_producto from Composicion)) 
	then 'COMPUESTO'
	else 'NO COMPUESTO'
	end as tipo

from Producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
where year(fact_fecha)<> 2012
and year(fact_fecha)<>null
group by prod_codigo, prod_detalle
order by sum(item_cantidad) desc

--FRAN
select prod_codigo,
		prod_detalle, 
		CASE WHEN prod_codigo in (select comp_producto from Composicion) 
		then 'compuesto' 
		else 'no es compuesto' 
		end as tipo
from factura 
join Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
join Producto on prod_codigo = item_producto
where prod_codigo not in (select item_producto from Factura join Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
							where year(fact_fecha)=2012)
group by prod_codigo,prod_detalle
order by sum(item_cantidad) desc

--F2
select prod_codigo,prod_detalle, CASE WHEN prod_codigo in (select comp_producto from Composicion) 
	then 'es compuesto' else 'no es compuesto' end
from Item_Factura 
join Producto on prod_codigo = item_producto
where prod_codigo not in (select item_producto 
							from Factura 
							join Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
							where year(fact_fecha)=2012)
group by prod_codigo,prod_detalle
order by sum(item_cantidad) desc

--KIKE
select prod_codigo, prod_detalle, 
	case when(prod_codigo in (select distinct comp_producto from Composicion)) 
	then 'COMPUESTO'
	else 'NO COMPUESTO'
	end as tipo

from Producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_numero + fact_tipo + fact_sucursal = item_numero+ item_tipo+ item_sucursal
where year(fact_fecha) < 2012
and prod_codigo not in (select item_producto from Factura join Item_Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
							where year(fact_fecha)=2012)
group by prod_codigo, prod_detalle
order by sum(item_cantidad) desc

--PRACTICA--------------------------------------------------------------------------------------------------------
/* Realizar una consulta que considerando solo las facturas en las cuales se vendieron productos
con composicion y sin composicion muestre:
	nombre de producto sin composicion, 
	nombre de producto con composicion, 
	cantidad de facts,
	monto facturado
No se deben repetir pares de productos en la consulta */

select p1.prod_detalle, 
		p2.prod_detalle, 
		count(distinct fact_tipo+fact_sucursal+fact_numero), 
		sum(fact_total)
from Factura
join Item_Factura i1 on i1.item_numero+i1.item_sucursal+i1.item_tipo = fact_numero+fact_sucursal+fact_tipo
join Item_Factura i2 on i2.item_numero+i2.item_sucursal+i2.item_tipo = fact_numero+fact_sucursal+fact_tipo
join producto p1 on p1.prod_codigo=i1.item_producto
join producto p2 on p2.prod_codigo=i2.item_producto

where i1.item_producto < i2.item_producto
and
i1.item_producto in(select comp_producto from Composicion)
and
i2.item_producto not in(select comp_producto from Composicion)
group by p1.prod_detalle, p2.prod_detalle
order by 1,2

/*se pide realizar una consulta SQL q retorne:
la razon social de los 15 clientes que posean menor limite de credito, el promedio en $ de las compras realizadas por ese cliente y que se indique un string 
"compro productos compuestos" en caso que alguno de todos los productos comprados tenga composicion.
considerar solo aquellos clientes que tengan alguna factura mayor a 350000(facT_total)
se debera ordenar los resultados por el domicilio del cliente*/

select top 15 clie_razon_social,
			AVG(fact_total),
			case when(fact_cliente in (select fact_cliente 
										from Item_Factura 
										join Factura f2 on item_numero+item_sucursal+item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo 
										where item_producto in (select comp_producto from Composicion)))
			then 'compro productos compuestos'
			else '-'
			end
from Factura
join cliente on fact_cliente = clie_codigo
group by clie_razon_social, clie_codigo, fact_cliente, clie_domicilio, clie_limite_credito
having clie_codigo in(select fact_cliente from factura where fact_total > 350)
order by clie_limite_credito asc,clie_domicilio desc

--=> NO ORDENA POR DOMICILIOOOOO XD

select clie_razon_social,
			AVG(fact_total),
			case when(fact_cliente in (select fact_cliente 
										from Item_Factura 
										join Factura f2 on item_numero+item_sucursal+item_tipo = f2.fact_numero+f2.fact_sucursal+f2.fact_tipo 
										where item_producto in (select comp_producto from Composicion)))
			then 'compro productos compuestos'
			else '-'
			end
from cliente
join factura on fact_cliente = clie_codigo
where clie_codigo in (select top 15 clie_codigo 
						from Cliente 
						group by clie_codigo,clie_limite_credito
						having clie_codigo in(select fact_cliente from factura where fact_total > 350) 
						order by clie_limite_credito asc)
group by clie_razon_social, clie_codigo, fact_cliente, clie_domicilio, clie_limite_credito
order by clie_domicilio asc

/* mostrar los 2 empleados del mes: estos son
a) el empleado que en el mes actual (en el cual se ejecuta la query) vendio mas en dinero (fact_total)
b) el segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) vendio 
mas cantidades (unidades de productos)
se debera mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 
(mejor facturacion y para el segundo vendido mas unidades)
nota -> si el empleado que mas vendio en facturacion y cantidades es el mismo, solo mostrar una fila que 
diga el empleado y "mejor en todo"
*/

select empl_nombre + empl_apellido
from Empleado
where empl_codigo in (select top 1 fact_vendedor 
						from Factura 
						where month(fact_fecha)=MONTH(GETDATE()) and year(fact_fecha)=year(getdate())  
						group by fact_vendedor 
						order by sum(fact_total)desc)
or
empl_codigo in (select top 1 fact_vendedor 
						from Item_Factura 
						join Factura on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo 
						where month(fact_fecha)=MONTH(GETDATE()) and year(fact_fecha)=year(getdate())  
						group by fact_vendedor 
						order by sum(item_cantidad)desc)

---------HORRIBLEEEEEEEEEEEEEEEEEEEEEEEEEEEE
select rtrim(e1.empl_apellido)+ ' ' + ltrim(e1.empl_nombre) Empleado,
       case 
       when(e1.empl_codigo in (select top 1 fact_vendedor from Factura where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(fact_total) desc))
       then('Mejor facturacion')
       when(e1.empl_codigo in (select top 1 fact_vendedor from Factura join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                                    where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(item_cantidad) desc))
       then('Vendio mas unidades')
       when((e1.empl_codigo in (select top 1 fact_vendedor from Factura where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(fact_total) desc))
    and
    (e1.empl_codigo in (select top 1 fact_vendedor from Factura join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                                    where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(item_cantidad) desc)))    
       then('Mejor en todo')  
       end String,
       sum(fact_total) ,
       sum(item_Cantidad)
from Empleado e1
join factura on e1.empl_codigo = fact_vendedor
join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero 
where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011
and    (e1.empl_codigo in (select top 1 fact_vendedor from Factura where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(fact_total) desc))
    or
    (e1.empl_codigo in (select top 1 fact_vendedor from Factura join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero
                                    where month(fact_Fecha) = month(getdate()) and year(fact_fecha) = 2011 group by fact_vendedor order by sum(item_cantidad) desc))
group by empl_nombre,empl_apellido,empl_codigo, fact_Fecha
order by sum(fact_total)

/*
Mostrar las zonas donde menor cantidad de ventas se estan realizando en el anio actual. Recordar que un empleado esta puesto como fact_vendedor en factura. 
de aquellas zonas donde menores ventas tengamos, se debera mostrar (cantidad de clientes distintos que operan en esa zona), cantidad de clientes que aparte 
de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). El resultado se debera mostrar por cantidad de productos vendidos en la zona 
de manera descendiente.
*/

select zona_codigo,
		count(distinct fact_cliente),
		(select count(distinct f2.fact_cliente)
		from factura f2
		where f2.fact_cliente = fact_cliente
		and f2.fact_cliente in (select fact_cliente
								from factura
								join Empleado on empl_codigo = fact_vendedor
								join Departamento on depa_codigo = empl_departamento
								where depa_zona <> zona_codigo))

from Zona
join Departamento on depa_zona = zona_codigo
join Empleado on empl_departamento = depa_codigo
join Factura on fact_vendedor = empl_codigo
join Item_Factura on fact_tipo + fact_sucursal + fact_numero = item_tipo + item_sucursal + item_numero 

group by zona_codigo 
order by count(distinct fact_sucursal+fact_tipo+fact_numero) asc, sum(item_cantidad) desc

/*
para cada producto q no fue vendido en el 2012, la siguiente informacion
	1) detalle del producto
	2) rubro del prod
	3) cantidad de prods q tiene el rubro
	4) precio max de venta en toda la historia, si no tiene ventas en la historia mostrar 0
el resultado debera mostrar primero aquellos prods que tienen composicion
*/

select prod_detalle, prod_rubro,
		(select count(distinct p1.prod_codigo) from Producto p1 where prod_rubro = p1.prod_rubro) cant_rubro,
		isnull(max(item_precio),0) precio_max
from Item_Factura
right join Producto on item_producto = prod_codigo
where prod_codigo not in (select item_producto
							from Item_Factura
							join Factura on item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
							where year(fact_fecha) = 2012)
group by prod_detalle, prod_rubro, prod_codigo
order by (select count(comp_componente) from Composicion where comp_producto=prod_codigo) desc


/* se requiere mostrar los productos que sean componentes y que se hayan 
vendido en forma unitaria o a traves del producto al cual compone, por ejemplo
una hamburguesa se debera mostrar si se vendio como hamburguesa y si se vendio un combo que esta compuesto
por una hamburguesa
se debera mostrar
codigo de producto, nombre de producto, cantidad de facturas vendidas solo, cantidad de facturas
vendidas de los productos qeu compone, cantidad de productos a los cuales
compone que se vendieron
el resultado debera ser ordenado por el componente que se haya vendido solo en mas facturas
resolver sin subselects :D */

select prod_codigo, prod_detalle,
		count(distinct i2.item_numero+i2.item_tipo+i2.item_sucursal),
		count(distinct i1.item_numero+i1.item_tipo+i1.item_sucursal),
		count(i1.item_cantidad)
		
from Producto
join Composicion c1 on c1.comp_componente = prod_codigo

join Item_Factura i1 on i1.item_producto = c1.comp_producto

join Item_Factura i2 on i2.item_producto = prod_codigo

group by prod_codigo, prod_detalle
order by 3 desc

/* 
REALIZAR UNA CONSULTA SQL QUE RETORNE PARA LOS 10 CLIENTES QUE MAS COMPRARON EN EL 2012 Y QUE FUERON
ATENDIDOS POR MAS DE 3 VENDEDORES DISTINTOS:
	APELLIDO Y NOMBRE DLE CLIENTE
	CANTIDAD DE PRODUCTOS DISTINTOS COMPRADOS EN EL 2012
	CANTIDAD DE UNIDADES COMPRADAS DENTRO DEL PRIMER SEMESTRE DEL 2012
EL RESULTADO DEBERA MOSTRAR ORDENADO LA CANTIDAD DE VENTAS DESCENDENTE DEL 2012 DE CADA
CLIENTE, NE CASO DE IGUALDAD DE VENTAS, ORDENAR POR CODIGO DE CLIENTE
*/

select top 10 clie_razon_social,
				count(distinct item_producto) prods_distintos,
				(select sum(item_cantidad) 
					from Item_Factura i2
					join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero= i2.item_tipo+i2.item_sucursal+i2.item_numero
					where year(fact_fecha) = 2012
					and f2.fact_cliente=clie_codigo
					and MONTH(fact_fecha) < 7) unidades_compradas
from Cliente
join Factura on fact_cliente = clie_codigo
join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
where year(fact_fecha)=2012 
group by clie_razon_social, clie_codigo
having count(distinct fact_vendedor)>3
order by count(distinct fact_tipo+fact_sucursal+fact_numero) desc, clie_codigo asc

/*
armar una consulta SQL que muestre clientes que en 2 anios consecutivos (de existir ) fueron los
mejores compradores, es decir, los que en monto total facturado anual fue el maximo. de esos 
clientes, mostrar razon social, domicilio, cantidad de unidades compradas en el ultimo anio
*/

select top 1 clie_razon_social, clie_domicilio, 
			(select sum(item_cantidad) 
			from factura
			join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
			where year(fact_fecha) = (select MAX(year(fact_fecha)) from Factura )
			and
			fact_cliente = clie_codigo)
from Cliente
join Factura on fact_cliente = clie_codigo
where --NOSE
group by clie_razon_social, clie_domicilio, clie_codigo

/*
Realizar una consulta SQL que retorne todos los años en donde se vendieron más cantidad de
productos compuestos que sin composición.
Sobre estos registros mostrar: Año, cliente que más compro composiciones.
El resultado debe ser ordenado por monto total comprado de todos los  productos por año.
Nota: No se permite el uso de sub-selects en el FROM para este punto.
*/

select year(fact_fecha),
		(select top 1 fact_cliente 
		from Factura
		join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
		where year(fact_fecha) = year(fact_fecha)
		and item_producto in (select comp_producto from Composicion)
		group by fact_cliente
		order by sum(item_cantidad) desc)
		
from Factura
join Item_Factura i1 on fact_tipo+fact_sucursal+fact_numero= i1.item_tipo+i1.item_sucursal+i1.item_numero
join Item_Factura i2 on fact_tipo+fact_sucursal+fact_numero= i2.item_tipo+i2.item_sucursal+i2.item_numero
where i1.item_producto in (select comp_producto from Composicion)

group by year(fact_fecha)

having sum(i1.item_cantidad) > (select sum(i3.item_cantidad) 
								from Item_Factura i3
								join Factura f3 on I3.item_tipo+I3.item_sucursal+I3.item_numero=F3.fact_tipo+F3.fact_sucursal+F3.fact_numero
								where year(fact_fecha) = year(f3.fact_fecha)
								and item_producto not in(select comp_producto from Composicion))

order by sum(i2.item_cantidad * i2.item_precio)


--------------

select year(fact_fecha),
		
from Factura
join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
where (select sum(item_cantidad) 
		from Item_Factura
		join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero= item_tipo+item_sucursal+item_numero
		where year(fact_fecha) = year(f2.fact_fecha)
		and item_producto in (select comp_producto from Composicion)
		) > (select sum(item_cantidad) 
				from Item_Factura
				join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero= item_tipo+item_sucursal+item_numero
				where year(fact_fecha) = year(f2.fact_fecha)
				and item_producto not in (select comp_producto from Composicion)
				)

------------------

/*
Armar una consulta que muestre para todos los productos:
	Producto
	Detalle del producto
	Detalle composición (si no es compuesto un string “SIN COMPOSICION”,, si es compuesto un string
	“CON COMPOSICION”
	Cantidad de Componentes (si no es compuesto, tiene que mostrar 0)
	Cantidad de veces que fue comprado por distintos clientes
*/

select prod_codigo,prod_detalle,
		case when(prod_codigo in (select comp_producto from Composicion))
		then 'CON COMP'
		else 'SIN COMP'
		end detalle_comp,
		isnull(sum(comp_cantidad),0),
		(select count(distinct fact_cliente)
		 from Factura
		 join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
		 where item_producto = prod_codigo)

from Producto
left join Composicion on prod_codigo = comp_producto
group by prod_codigo,prod_detalle

/*
Armar una estadística que muestre:
Año, Mes, Razón Social Cliente, Rubro, Familia, Cantidad de unidades de de ese rubro/familia
SUMANDO solo aquellos clientes que llegaron a comprar más en monto de ese rubro/familia en el
2012 que en el 2011.
Nota: No se permiten sub select en el FROM.
*/

select year(fact_fecha), MONTH(fact_fecha), clie_razon_social, prod_rubro, prod_familia, sum(item_cantidad)
from cliente
join Factura on fact_cliente = clie_codigo
join Item_Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
join Producto on item_producto = prod_codigo
group by year(fact_fecha), MONTH(fact_fecha), clie_razon_social, prod_rubro, prod_familia
having (select sum(i2.item_cantidad*i2.item_precio)
		from Factura f2
		join Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero= i2.item_tipo+i2.item_sucursal+i2.item_numero
		join Producto p2 on p2.prod_codigo = i2.item_producto
		where year(f2.fact_fecha) = 2012
		and f2.fact_cliente = fact_cliente
		and p2.prod_rubro = prod_rubro
		and p2.prod_familia = prod_familia) > (select sum(i2.item_cantidad*i2.item_precio)
		from Factura f2
		join Item_Factura i2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero= i2.item_tipo+i2.item_sucursal+i2.item_numero
		join Producto p2 on p2.prod_codigo = i2.item_producto
		where year(f2.fact_fecha) = 2011
		and f2.fact_cliente = fact_cliente
		and p2.prod_rubro = prod_rubro
		and p2.prod_familia = prod_familia)


/*
1) Se necesita saber que productos no son vendidos durante el año 2011 y cuales si. La consulta
debe mostrar:
1. Código de producto
2. Nombre de Producto
3. Fue Vendido (Si o No) según el caso.
4. Cantidad de componentes.
El resultado deberá ser ordenado por cantidad total de clientes que los compraron en la historia
ascendente.
*/

select p.prod_codigo, p.prod_detalle,
		case when(exists(select item_producto 
						from Item_Factura 
						join Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
						where year(fact_fecha)=2011
						and p.prod_codigo=item_producto))
		then 'SI'
		else 'NO' 
		end fue_vendido,
		isnull((select sum(comp_cantidad) 
				from Composicion
				where comp_producto=p.prod_codigo),0) componentes

from Producto p
right join Item_Factura on item_producto=p.prod_codigo
join Factura on fact_tipo+fact_sucursal+fact_numero= item_tipo+item_sucursal+item_numero
where year(fact_fecha) = 2011
group by p.prod_codigo, p.prod_detalle
order by (select count(distinct fact_cliente) 
			from factura 
			join Item_Factura i1 on fact_tipo+fact_sucursal+fact_numero= i1.item_tipo+i1.item_sucursal+i1.item_numero
			where i1.item_producto=prod_codigo
			group by item_producto) asc

