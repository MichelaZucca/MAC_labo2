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


/*
	Créer un index sur la colonne no ??
    
    Champ doirt_lecture_ecriture énuméré spécifiant :
		- Aucun droit
        - Lecture seule
        - lecture / ecriture
        
        
	DONNEES DU LABO 
	Placez-vous en mode administrateur (root) et créer une base de données Transactions 
    • Créer toutes les tables nécessaires (y compris la table journal, la table ou les tables d’association) 
    • Dans MySQL, créer les utilisateurs suivants (CREATE USER..) qui devraient pouvoir accéder depuis n’importe où (en local ou à distance). 
		o Un Administrateur de la base de données 
        o 3 clients U1, U2 et U3  
	• Droits associés (GRANT..) 
		o L’administrateur aura tous les droits 
        o Les clients n’auront aucun droit sur aucune des tables, sinon le droit d’exécuter des procédures stockées. 
	• L’administrateur utilisera la base de données directement en console, en s’assurant que les contraintes de la base de données sont respectées 
	  (sa responsabilité). 
	
    Ecrire néanmoins un trigger qui empêchera la suppression d’un compte par l’administrateur si le solde du compte n’est pas égal à zéro. 
    
    • Ecrire 2 procédures stockées, qui permettront respectivement à un client: 
		o de lire l’état d’un compte 
        o de faire un dépôt sur un compte REMARQUES !  
        
        1. La procédure permettant de faire un retrait sur un compte n’est pas demandée ! 
        2. Dans cette première étape les transactions opérées sur les comptes, qu’il s’agisse de lecture ou d’écriture, se feront sans se soucier des 
           problèmes de concurrence : ignorer tout aspect lié au verrouillage. 
           
           Par contre, les autres contrôles devront être opérés:  Toute opération illicite sera refusée et la procédure, outre le fait d’avoir enregistrer
           l’opération dans le journal, devra générer une erreur. 
	
    • Tester avec deux comptes : 
    • un compte propriété de U1, partagé en lecture/écriture entre U1 et U2,  
    • un compte propriété de U1, partagé entre U1 et U3, dont seul U1 aura le droit en écriture 
 */
