/*
	Affiche l'état d'un compte. 
    
    Paramètres:
    id_compte: l'ID du compte
*/
DROP PROCEDURE IF EXISTS lire_etat_compte;
DELIMITER //
CREATE PROCEDURE lire_etat_compte (id_compte INT)
BEGIN
	DECLARE username VARCHAR(30);
    DECLARE id_client INT;
    DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    DECLARE solde FLOAT;
    
    # Get the current solde for logging purposes
    SELECT comptes.solde INTO solde FROM Transactions.comptes WHERE comptes.id = id_compte;
    
	# Get the current username 
    SELECT USER() INTO username;
    SELECT substring_index(username, '@', 1) INTO username;
    SELECT clients.id INTO id_client FROM Transactions.clients WHERE clients.nom = username;
    
    # Chek if the user has the right to read the account
    SELECT acces.acces INTO user_acces
    FROM Transactions.acces 
    WHERE acces.id_compte = id_compte AND acces.id_client = id_client;
    
    # If everything alright read account
    IF user_acces = 'lecture' OR user_acces = 'lecture-ecriture' THEN 
		
		SELECT 
			comptes.id,
			comptes.num, 
			comptes.solde, 
			comptes.min_autorise, 
			comptes.max_retrait_journalier, 
			clients.nom
		FROM Transactions.comptes
		INNER JOIN clients ON comptes.propietaire = clients.id
		WHERE comptes.id = id_compte;
        
		CALL log_journal(
			id_compte,
			id_client,
            'lecture',
            0, 
            solde,
            solde
		);
	ELSE 
        CALL log_journal(
			id_compte,
			id_client,
            'lecture',
            3, 
            solde,
            solde
		);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
    END IF;
    
    /*
    log_journal(
		id_compte,
		
	)
    */
    
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

	DECLARE id_compte INT;
    SELECT comptes.id INTO id_compte 
    FROM Transactions.comptes 
    WHERE comptes.num = num_compte;
    
    CALL lire_etat_compte(id_compte);
    
END //

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