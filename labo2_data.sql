/*
	Créer les utilisateurs avec leurs droit d'accès
    
    Créer les datas
    
*/

-- Create user in MYSQL
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
CREATE USER IF NOT EXISTS 'U1'@'%' IDENTIFIED BY 'U1';
CREATE USER IF NOT EXISTS 'U2'@'%' IDENTIFIED BY 'U2';
CREATE USER IF NOT EXISTS 'U3'@'%' IDENTIFIED BY 'U3';

-- Access
GRANT ALL PRIVILEGES ON Transactions.* TO 'admin'@'%'  WITH GRANT OPTION;
GRANT EXECUTE ON Transactions.* TO 'U1'@'%';
GRANT EXECUTE ON Transactions.* TO 'U2'@'%';
GRANT EXECUTE ON Transactions.* TO 'U3'@'%';

-- Insert client in the database
INSERT INTO Transactions.clients (nom) VALUES ('U1');
INSERT INTO Transactions.clients (nom) VALUES ('U2');
INSERT INTO Transactions.clients (nom) VALUES ('U3');



-- Create account (U1's property) with shared access (read/write) between U1 and U2
INSERT INTO Transactions.comptes (num, solde, min_autorise, max_retrait_journalier, blocage, propietaire)
VALUES ('1', 0, 0, 1000, FALSE, (SELECT id FROM clients WHERE nom = 'U1'));

INSERT INTO Transactions.Acces (no_Compte, num_Client, acces)
VALUES ('1', (SELECT id FROM clients WHERE nom = 'U1'), 'lecture-ecriture');

INSERT INTO Transactions.Acces (no_Compte, num_Client, acces)
VALUES ('1', (SELECT id FROM clients WHERE nom = 'U2'), 'lecture-ecriture');


-- Create account (U1's property) with shared access between U1 and U2
INSERT INTO Transactions.comptes (num, solde, min_autorise, max_retrait_journalier, blocage, propietaire)
VALUES ('2', 0, 0, 1000, FALSE, (SELECT id FROM clients WHERE nom = 'U1'));

INSERT INTO Transactions.Acces (no_Compte, num_Client, acces)
VALUES ('2', (SELECT id FROM clients WHERE nom = 'U1'), 'ecriture');

INSERT INTO Transactions.Acces (no_Compte, num_Client, acces)
VALUES ('2', (SELECT id FROM clients WHERE nom = 'U3'), 'aucun');
