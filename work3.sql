--Задача: Написание хранимой процедуры для обновления данных о клиентах с обработкой ошибок и ведением журнала изменений.

--Для начала я создам базу данных
CREATE DATABASE ClientDatabase;
GO

USE ClientDatabase;
GO

CREATE TABLE Clients (
  id INT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL
);

CREATE TABLE ChangeLog (
  id INT PRIMARY KEY,
  client_id INT NOT NULL,
  change_date DATE NOT NULL,
  change_type VARCHAR(50) NOT NULL,
  old_value VARCHAR(255) NULL,
  new_value VARCHAR(255) NULL,
  FOREIGN KEY (client_id) REFERENCES Clients(id)
);

--Хранимая процедура для обновления данных о клиентах

CREATE PROCEDURE UpdateClient
  @id INT,
  @name VARCHAR(255),
  @email VARCHAR(255),
  @phone VARCHAR(20)
AS
BEGIN TRANSACTION;

BEGIN TRY
  UPDATE Clients
  SET name = @name, email = @email, phone = @phone
  WHERE id = @id;

  INSERT INTO ChangeLog (client_id, change_date, change_type, old_value, new_value)
  SELECT @id, GETDATE(), 'UPDATE', c.name, @name
  FROM Clients c
  WHERE c.id = @id;

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  ROLLBACK TRANSACTION;

  DECLARE @ErrorMessage NVARCHAR(4000);
  SET @ErrorMessage = ERROR_MESSAGE();

  INSERT INTO ChangeLog (client_id, change_date, change_type, old_value, new_value)
  VALUES (@id, GETDATE(), 'ERROR', '', @ErrorMessage);

  RAISERROR (@ErrorMessage, 16, 1);
END CATCH;
GO

--Пример вызова хранимой процедуры

EXEC UpdateClient 1, 'John Doe', 'johndoe@example.com', '1234567890';

/*В этом примере я создал базу данных ClientDatabase с двумя таблицами: Clients для хранения данных о клиентах и ChangeLog для ведения журнала изменений. 
Затем я написал хранимую процедуру UpdateClient, которая обновляет данные о клиенте и записывает изменения в журнал изменений.
Если происходит ошибка, процедура откатывает транзакцию и записывает ошибку в журнал изменений.*/
