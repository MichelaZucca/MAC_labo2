/*
	Créer les utilisateurs avec leurs droit d'accès
    
    Créer les datas
    
*/

CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin';
CREATE USER IF NOT EXISTS 'U1'@'%' IDENTIFIED BY 'U1';
CREATE USER IF NOT EXISTS 'U2'@'%' IDENTIFIED BY 'U2';
CREATE USER IF NOT EXISTS 'U3'@'%' IDENTIFIED BY 'U3';

-- WITH GRANT OPTION = edit the permissions of other users
GRANT ALL PRIVILEGES ON Transactions.* TO 'admin'@'%'  WITH GRANT OPTION;

GRANT EXECUTE ON Transactions.* TO 'U1'@'%';
GRANT EXECUTE ON Transactions.* TO 'U2'@'%';
GRANT EXECUTE ON Transactions.* TO 'U3'@'%';
