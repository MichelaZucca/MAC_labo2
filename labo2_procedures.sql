/*
	Affiche l'état d'un compte. 
    
    Paramètres:
    id_compte: l'ID du compte
*/
DROP PROCEDURE IF EXISTS lire_etat_compte;
DELIMITER //
CREATE PROCEDURE lire_etat_compte (id_compte INT)
BEGIN
	
    DECLARE id_client INT;
    DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    DECLARE solde FLOAT;
    
    # Get the curren client ID for logging pruposes
	SELECT get_user_id() INTO id_client;
    
    # Get the current solde for logging purposes
    SELECT comptes.solde INTO solde FROM Transactions.comptes WHERE comptes.id = id_compte;
    
    SELECT get_user_compte_acces(id_compte) INTO user_acces;
	
    # If everything alright read account
    IF user_acces = 'lecture' OR user_acces = 'lecture-ecriture' THEN 
		
		SELECT 
			comptes.id,
			comptes.num, 
			comptes.solde, 
			comptes.min_autorise, 
			comptes.max_retrait_journalier, 
            comptes.blocage,
			clients.nom
		FROM Transactions.comptes
		INNER JOIN clients ON comptes.propietaire = clients.id
		WHERE comptes.id = id_compte;
        
		CALL log_journal(id_compte, id_client, 'lecture', 0, solde, solde);
	ELSE 
        CALL log_journal(id_compte, id_client, 'lecture', 3, solde, solde );
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
    END IF;
    
END //

/*
	Affiche l'état d'un compte.
    
    Paramètres:
    num_compte: le numéro de compte
*/
DROP PROCEDURE IF EXISTS lire_etat_compte_par_num //
DELIMITER //
CREATE PROCEDURE lire_etat_compte_par_num (num_compte VARCHAR(30) )
BEGIN
    
    CALL lire_etat_compte( (SELECT id FROM Transactions.comptes WHERE num = num_compte) );
    
END //

/*
	Déposer un montant sur un compte
*/
DROP PROCEDURE IF EXISTS deposer_sur_compte //
DELIMITER //
CREATE PROCEDURE deposer_sur_compte (id_compte INT, montant FLOAT)
BEGIN
    DECLARE id_client INT;
    DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    DECLARE solde FLOAT;
    DECLARE nouveau_solde FLOAT;

	
    
    # Get the curren client ID for logging pruposes
	SELECT get_user_id() INTO id_client;

    # Get the current solde for logging purposes
    SELECT comptes.solde INTO solde FROM Transactions.comptes WHERE comptes.id = id_compte;
    
    # Get the user account access rights 
    SELECT get_user_compte_acces(id_compte) INTO user_acces;
    
    IF user_acces = 'ecriture' OR user_acces = 'lecture-ecriture' THEN 
        
		UPDATE Transactions.comptes
        SET comptes.solde = solde + montant 
        WHERE comptes.id = id_compte;
        
		# Get the new solde for logging purposes
		SELECT comptes.solde INTO nouveau_solde FROM Transactions.comptes WHERE comptes.id = id_compte;
        
        CALL log_journal(id_compte, id_client, 'ecriture', 0, solde, nouveau_solde);
    ELSE
		 CALL log_journal(id_compte, id_client, 'ecriture', 4, solde, solde);
        
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have write access to that account.';
    END IF;
    
END //

/*
	Récupère le client ID de l'utilisateur MySQL courant.
*/
DROP FUNCTION IF EXISTS get_user_id //
DELIMITER //
CREATE FUNCTION get_user_id ()
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE username VARCHAR(30);
    DECLARE id_client INT;
    
    # Get the current username 
    SELECT USER() INTO username;
    SELECT substring_index(username, '@', 1) INTO username;
    SELECT clients.id INTO id_client FROM Transactions.clients WHERE clients.nom = username;
    
    RETURN id_client;

END//

/*
	Récupère le droit d'accès de l'utilisateur exécutant la fonction 
    sur le compte donné en paramètre.
*/
DROP FUNCTION IF EXISTS get_user_compte_acces //
DELIMITER //
CREATE FUNCTION get_user_compte_acces (id_compte INT)
RETURNS ENUM('lecture','ecriture','lecture-ecriture')
DETERMINISTIC
BEGIN
    DECLARE id_client INT;
	DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    
    SELECT get_user_id() INTO id_client;
    
    # Chek if the user has the right to read the account
    SELECT acces.acces INTO user_acces
    FROM Transactions.acces 
    WHERE acces.id_compte = id_compte AND acces.id_client = id_client;
    
    RETURN user_acces;

END//

/*
	Enregistrer une action dans la table de journal.
    
    Codes d'autorisation: 
		0: Succès
        1: Solde insuffisant
        2: max journalier dépassé
        3: lecture non-autorisée
        4: écriture non-autorisée
*/
DROP PROCEDURE IF EXISTS log_journal //
DELIMITER //
CREATE PROCEDURE log_journal(
	id_compte INT,
    id_client INT, 
    typeOperation ENUM('lecture', 'ecriture'),
    autorisation INT,
    solde_init FLOAT,
    solde_result FLOAT
)
BEGIN

	INSERT INTO Transactions.journal (date_val, id_compte, id_client, typeOperation, autorisation, etat_init, etat_result)
    VALUES (NOW(), id_compte, id_client, typeOperation, autorisation, solde_init, solde_result);

END //


DELIMITER ;