# Lire l'état d'un compte
DROP PROCEDURE IF EXISTS lire_etat_compte;
DELIMITER //
CREATE PROCEDURE lire_etat_compte (num_compte VARCHAR(30) )
BEGIN
	# TODO Check current user RW access rights
    
    # If everything alright read account
    
    SELECT 
		comptes.num, 
		comptes.solde, 
        comptes.min_autorise, 
        comptes.max_retrait_journalier, 
        clients.nom
    FROM Transactions.comptes
    INNER JOIN clients ON comptes.propietaire = clients.id
    WHERE comptes.num = num_compte;
    
END //