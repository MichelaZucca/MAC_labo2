use transactions;

DROP FUNCTION IF EXISTS has_write_acces //
DELIMITER //
CREATE FUNCTION has_write_acces (id_compte INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	DECLARE autorized BOOLEAN DEFAULT false;
    DECLARE id_client INT;
	DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    
	IF (SELECT COUNT(*) FROM Transactions.comptes WHERE id = id_compte) <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This account doesn\'t exist.';
    END IF;
    
    # Get the curren client ID for logging pruposes
	SELECT get_user_id() INTO id_client;
    
    SELECT get_user_compte_acces(id_compte) INTO user_acces;
	
    # If everything alright read account
    IF user_acces = 'ecriture' OR user_acces = 'lecture-ecriture' THEN 
		SET autorized = true;
	END IF;
    
    RETURN autorized;
END//

DROP FUNCTION IF EXISTS has_read_acces //
DELIMITER //
CREATE FUNCTION has_read_acces (id_compte INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	DECLARE autorized BOOLEAN DEFAULT false;
    DECLARE id_client INT;
	DECLARE user_acces ENUM('lecture','ecriture','lecture-ecriture');
    
	IF (SELECT COUNT(*) FROM Transactions.comptes WHERE id = id_compte) <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This account doesn\'t exist.';
    END IF;
    
    # Get the curren client ID for logging pruposes
	SELECT get_user_id() INTO id_client;
    
    SELECT get_user_compte_acces(id_compte) INTO user_acces;
	
    # If everything alright read account
    IF user_acces = 'lecture' OR user_acces = 'lecture-ecriture' THEN 
		SET autorized = true;
	END IF;
    
    RETURN autorized;
END//

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
    
    IF (SELECT COUNT(*) FROM Transactions.comptes WHERE id = id_compte) <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This account doesn\'t exist.';
    END IF;
    
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
		INNER JOIN clients ON comptes.proprietaire = clients.id
		WHERE comptes.id = id_compte;
        
		CALL log_journal(id_compte, id_client, 'lecture', 0, solde, solde);
	ELSE 
        CALL log_journal(id_compte, id_client, 'lecture', 3, solde, solde );
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
    END IF;
    
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
    
    # If the amount is less or 0, refuse the deposit
    IF montant <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can\'t deposit a negative amount of money.';
    ELSEIF (SELECT COUNT(*) FROM Transactions.comptes WHERE id = id_compte) <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This account doesn\'t exist.';
    END IF;
    
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
    type_operation ENUM('lecture', 'ecriture'),
    autorisation INT,
    solde_init FLOAT,
    solde_result FLOAT
)
BEGIN
 /*
		0 : Succès 
        1 : Solde insuffisant
        2 : Max journalier dépassé
        3 : Lecture non autoriséee
        4 : Ecriture non autorisée
 */
	INSERT INTO Transactions.journal (date_val, id_compte, id_client, type_operation, autorisation, etat_init, etat_result)
    VALUES (NOW(), id_compte, id_client, type_operation, autorisation, solde_init, solde_result);

END //


/*
      ********** PART TWO ***********
*/

/*
	Pas de commit automatique
*/
set @@autocommit=0;

/*
	Transferts d'un montant entre 2 comptes, aucune protection
    cpt1 : compte débité
    cpt2 : compte crédité
    montant : montant à transférer
    
    Remarques, par précisé si on gère le droit d'accès. Mais je pense que oui.. à confirmer lundi
*/
DROP PROCEDURE IF EXISTS transferer1 //
DELIMITER //
CREATE PROCEDURE transferer1(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
BEGIN
    DECLARE etat FLOAT;
	DECLARE id_compte INT ;
    DECLARE etat_before INT;
    DECLARE id_client INT;
    
    # récupère l'id du compte 
	SELECT id  INTO id_compte FROM comptes where comptes.num = cpt1;
    # récupère l'id de l'utilisateur
    SELECT get_user_id() INTO id_client;
    
    IF(has_write_acces(id_compte)) THEN
    
		SELECT solde INTO etat_before FROM comptes where comptes.num = cpt1;
		SET etat = etat_before - montant;
        # save dans le journal
		CALL log_journal(id_compte, id_client, 'lecture', 0, etat_before, etat_before);
		
		UPDATE Transactions.comptes
		SET comptes.solde = etat
		WHERE comptes.num = cpt1;
        # save dans le journal
        CALL log_journal(id_compte, id_client, 'ecriture', 0, etat_before, etat);
	   
       # PEUT-ON TRANSFERER SI ON EST PAS DETENTEUR DU COMPTE ??
       # SINON EXCEPTION
		SELECT solde INTO etat_before FROM comptes where comptes.num = cpt2;
		SET etat = etat_before + montant;
		# save dans le journal
		CALL log_journal(id_compte, id_client, 'lecture', 0, etat_before, etat_before);
        
		UPDATE Transactions.comptes
		SET comptes.solde = etat
		WHERE comptes.num = cpt2;
		# save dans le journal
        CALL log_journal(id_compte, id_client, 'ecriture', 0, etat_before, etat);
        
    ELSE
        SELECT solde INTO etat_before FROM comptes where comptes.num = cpt1;
        
		CALL log_journal(id_compte, id_client, 'lecture', 4, etat_before, etat_before);
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
    END IF;
    
END //

/*
	Transferts d'un montant entre 2 comptes, en mode transactionnel, 
    à savoir avec un  encadrement « start transaction commit », 
    mais sans opérer aucun verrouillage explicite.  
    
    cpt1 : compte débité
    cpt2 : compte crédité
    montant : montant à transférer
    
    Remarques, par précisé si on gère le droit d'accès. Mais je pense que oui.. à confirmer lundi
*/
DROP PROCEDURE IF EXISTS transferer2 //
DELIMITER //
CREATE PROCEDURE transferer2(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
BEGIN
	DECLARE etat FLOAT;  
	DECLARE id_compte INT ;
    DECLARE etat_before INT;
    DECLARE id_client INT;
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
	DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
    
    # récupère l'id du compte 
	SELECT id  INTO id_compte FROM comptes where comptes.num = cpt1;
    # récupère l'id de l'utilisateur
    SELECT get_user_id() INTO id_client;
    
    IF(has_write_acces(id_compte)) THEN
		
		# 1ère transaction on récupère le solde du compte cpt1 
		START TRANSACTION;
			SELECT solde INTO etat FROM comptes where comptes.num = cpt1;
		COMMIT; 
		SET etat = etat - montant;

		# 2ème transaction on met à jour le solde du compte cpt1 
		START TRANSACTION;
			UPDATE Transactions.comptes
			SET comptes.solde = etat
			WHERE comptes.num = cpt1;
		COMMIT;
		
		# 3ème transaction on récupère le solde du compte cpt2 
		START TRANSACTION;
			SELECT solde INTO etat FROM comptes where comptes.num = cpt2;
		COMMIT;
		SET etat = etat + montant;
		
		# 4ème transaction on met à jour le solde du compte cpt2 
		START TRANSACTION;
			UPDATE Transactions.comptes
			SET comptes.solde = etat
			WHERE comptes.num = cpt2;
		COMMIT;
        
    ELSE 
    
		START TRANSACTION;
			SELECT solde INTO etat_before FROM comptes where comptes.num = cpt1;
        COMMIT;
        
        START TRANSACTION;
			CALL log_journal(id_compte, id_client, 'lecture', 4, etat_before, etat_before);
        COMMIT;
        
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
        
    END IF;
END //

/*
	Transferts d'un montant entre 2 comptes, en travaillant en mode transactionnel, mais en opérant par vos 
    soins un verrouillage explicite des données sensibles en obéissant au « verrouillage en deux phases », 
    en verrouillant le plus tard possible.    
    
    cpt1 : compte débité
    cpt2 : compte crédité
    montant : montant à transférer
    
    Remarques, par précisé si on gère le droit d'accès. Mais je pense que oui.. à confirmer lundi
*/
DROP PROCEDURE IF EXISTS transferer3 //
DELIMITER //
CREATE PROCEDURE transferer3(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
BEGIN
	DECLARE etat FLOAT;
	DECLARE id_compte INT ;
    DECLARE etat_before INT;
    DECLARE id_client INT;
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION ROLLBACK;
	DECLARE EXIT HANDLER FOR SQLWARNING ROLLBACK;
		
	    # récupère l'id du compte 
	SELECT id  INTO id_compte FROM comptes where comptes.num = cpt1;
    # récupère l'id de l'utilisateur
    SELECT get_user_id() INTO id_client;
    
    IF(has_write_acces(id_compte)) THEN
    
	# 1ère transaction on récupère le solde du compte cpt1 
    # Pose le verrou de lecture 
	START TRANSACTION;
		SELECT solde INTO etat FROM comptes where comptes.num = cpt1 lock in share mode;
	COMMIT; 
	SET etat = etat - montant;

	# 2ème transaction on met à jour le solde du compte cpt1 
    # Pose le verrou d'ecriture 
    SELECT solde FROM comptes WHERE comptes.num = cpt1 FOR UPDATE;
    START TRANSACTION;
		UPDATE Transactions.comptes
		SET comptes.solde = etat
		WHERE comptes.num = cpt1;
	COMMIT;
	
    # 3ème transaction on récupère le solde du compte cpt2 
    # Pose le verrou de lecture 
	START TRANSACTION;
		SELECT solde INTO etat FROM comptes where comptes.num = cpt2 lock in share mode;
	COMMIT;
	SET etat = etat + montant;
    
    # 4ème transaction on met à jour le solde du compte cpt2 
	# Pose le verrou d'ecriture 
    SELECT solde FROM comptes WHERE comptes.num = cpt2 FOR UPDATE;
	START TRANSACTION;
		UPDATE Transactions.comptes
		SET comptes.solde = etat
		WHERE comptes.num = cpt2;
	COMMIT;
    ELSE
    
		START TRANSACTION;
			SELECT solde INTO etat_before FROM comptes where comptes.num = cpt1  lock in share mode;
        COMMIT;
        
        START TRANSACTION;
			CALL log_journal(id_compte, id_client, 'lecture', 4, etat_before, etat_before);
        COMMIT;
        
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You don\'t have read access to that account.';
        
    END IF;
END //

/*
	Transferts d'un montant entre 2 comptes, en travaillant en mode transactionnel, mais en opérant par vos 
    soins un verrouillage explicite des données sensibles en obéissant au « verrouillage en deux phases », 
    en verrouillant le plus tard possible.    
    
    cpt1 : compte débité
    cpt2 : compte crédité
    montant : montant à transférer
    
    Remarques, par précisé si on gère le droit d'accès. Mais je pense que oui.. à confirmer lundi
*/

DELIMITER ;



