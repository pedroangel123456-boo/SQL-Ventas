# Proyecto: Registro de Ventas Automatizado con SQL Server

Este repositorio contiene la lógica para un sistema de ventas funcional, enfocado en la integridad de los datos y el control de inventarios.

## Arquitectura del Procedimiento `sp_RegistrarVenta`

### `TRy CATCH` y Transacciones
Lo primero fue meter todo en un bloque `BEGIN TRY` 
* **`BEGIN TRANSACTION`**: Abrimos una cajita y todo lo que esta en la cajita lo podemos utilizar
* **`ROLLBACK`**: Si algo falla en el camino, el `CATCH` cierra la cajita y todo regresa como estaba antes

### Fase de Validación 

 Hago un `IF NOT EXISTS` en la tabla `Cliente`. Si no está, para qué le sigo , ¿no? xd
 Buscamos el `IdProducto` en el catálogo.
 Comparamos la `Existencia` actual contra lo que pide el cliente. Si pide más de lo que hay, lanzamos un `THROW`  para detener el proceso.

### Captura de Datos 

* Usamos un `SELECT` para jalar el **Precio Actual** directamente de la tabla `Producto`. Así nos aseguramos de cobrar lo que dice el sistema hoy, no lo que el cliente diga.
* Usamos `GETDATE()` para que la fecha sea la del servidor en ese microsegundo exacto.

### La Conexión `SCOPE_IDENTITY()`

* Primero insertamos en la tabla `Venta`.
* Inmediatamente después, usamos `SET @NuevaVentaID = SCOPE_IDENTITY();`. Esto captura el ID autogenerado de esa venta específica. 
* Ese ID lo usamos para el `INSERT` en `DetalleVenta`. Sin esto, el detalle no sabría a qué venta pertenece. Es el pegamento de todo el proceso.

### Actualización de Inventario 
Ya que todo está validado y guardado, el último paso es el `UPDATE` a la tabla `Producto`. Restamos la cantidad vendida (`Existencia = Existencia - @Cantidad`), ejecutamos el `COMMIT TRANSACTION` para que los cambios sean permanentes.

---

