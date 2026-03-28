-- tabla de los clientes
CREATE TABLE Cliente (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100),
    Pais NVARCHAR(50),
    Ciudad NVARCHAR(50)
);

-- tabla de los productos 
CREATE TABLE Producto (
    IdProducto INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100),
    Precio MONEY,
    Existencia INT
);

-- tabla de las ventas
CREATE TABLE Venta (
    IdVenta INT PRIMARY KEY IDENTITY(1,1),
    Fecha DATETIME DEFAULT GETDATE(),
    IdCliente INT,
    CONSTRAINT FK_Venta_Cliente FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);

-- tabla de las ventas
CREATE TABLE DetalleVenta (
    IdVenta INT NOT NULL,
    IdProducto INT NOT NULL,
    PrecioVenta MONEY NOT NULL,
    Cantidad INT NOT NULL,
    CONSTRAINT PK_DetalleVenta PRIMARY KEY (IdVenta, IdProducto),
    CONSTRAINT FK_DV_Venta FOREIGN KEY (IdVenta) REFERENCES Venta(IdVenta),
    CONSTRAINT FK_DV_Producto FOREIGN KEY (IdProducto) REFERENCES Producto(IdProducto)
);





CREATE PROCEDURE sp_RegistrarVenta
    @IdCliente INT,
    @IdProducto INT,
    @CantidadSolicitada INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) errores y transaccion
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 2) VALIDAR SI EL CLIENTE EXISTE
        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE IdCliente = @IdCliente)
            THROW 50001, 'Error .', 1;

        -- datos del producto
        DECLARE @PrecioActual MONEY, @StockActual INT;
        SELECT @PrecioActual = Precio, @StockActual = Existencia 
        FROM Producto WHERE IdProducto = @IdProducto;

        IF @PrecioActual IS NULL
            THROW 50002, 'Error: El producto no existe.', 1;

        -- existencia
        IF @StockActual < @CantidadSolicitada
            THROW 50003, 'Error: No hay suficiente existencia en inventario.', 1;

        -- ventas con fecha y id cliente
        INSERT INTO Venta (Fecha, IdCliente) VALUES (GETDATE(), @IdCliente);
        
        
        DECLARE @NuevaVentaID INT = SCOPE_IDENTITY();

        -- detalles del registro
        INSERT INTO DetalleVenta (IdVenta, IdProducto, PrecioVenta, Cantidad)
        VALUES (@NuevaVentaID, @IdProducto, @PrecioActual, @CantidadSolicitada);

        -- update de la existencia :)
        UPDATE Producto 
        SET Existencia = Existencia - @CantidadSolicitada
        WHERE IdProducto = @IdProducto;

        
        COMMIT TRANSACTION;
        PRINT 'Venta registrada con éxito y stock actualizado.';

    END TRY
    BEGIN CATCH
        -- Si algo falla, deshacemos los cambios
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
