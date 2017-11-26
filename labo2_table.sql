DROP SCHEMA IF EXISTS Transactions;
CREATE SCHEMA Transactions;
USE Transactions;

CREATE TABLE clients(
  id INT NOT NULL AUTO_INCREMENT,
  nom VARCHAR(30) NOT NULL UNIQUE,
  
  PRIMARY KEY (id) 
);

CREATE TABLE comptes (
  id INT NOT NULL AUTO_INCREMENT,
  num VARCHAR(30) NOT NULL UNIQUE,
  solde FLOAT,
  min_autorise FLOAT,
  max_retrait_journalier FLOAT,
  blocage BOOLEAN,
  proprietaire INT,
  
  PRIMARY KEY (id),
  CONSTRAINT fx_proprietaire FOREIGN KEY (proprietaire) REFERENCES clients(id)
);

CREATE TABLE acces (
  id_compte INT NOT NULL,
  id_client INT NOT NULL,
  acces ENUM('lecture','ecriture','lecture-ecriture') NOT NULL ,
  
  PRIMARY KEY (id_compte, id_client),
  CONSTRAINT fx_id_Client FOREIGN KEY (id_client) REFERENCES clients(id),
  CONSTRAINT fx_id_Compte FOREIGN KEY (id_compte) REFERENCES comptes(id)
);

CREATE TABLE journal (
  id INT NOT NULL AUTO_INCREMENT,
  date_val DateTime, 
  id_compte INT,
  id_client INT, 
  type_operation ENUM('lecture', 'ecriture'),
  autorisation INT,
  etat_init FLOAT,
  etat_result FLOAT,
  
  PRIMARY KEY(id),
  CONSTRAINT fx_compte FOREIGN KEY (id_compte) REFERENCES comptes(id),
  CONSTRAINT fx_client FOREIGN KEY (id_client) REFERENCES clients(id)
);


-- Trigger before delete account
DROP TRIGGER IF EXISTS check_solde;
DELIMITER //
CREATE TRIGGER check_solde BEFORE DELETE ON Transactions.comptes
  FOR EACH ROW BEGIN
    IF OLD.solde > 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account must be empty';
    END IF;	
END //
