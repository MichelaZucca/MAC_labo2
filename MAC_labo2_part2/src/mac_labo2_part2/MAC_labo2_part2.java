/**
 * MAC Labo 2 - partie 2
 * Programme de test d'accès à la base de données
 * Mathieu Monteverde, Sathyia Kirushnapillai et Michela Zucca
 */
package mac_labo2_part2;

import java.sql.ResultSet;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MAC_labo2_part2 {

//    public void etatComptes() {
//        try {
//            // TODO appel de la procédure choisie
//            ResultSet result = statement.executeQuery("Select * from comptes");
//            while (result.next()) {
//                int id = result.getByte("id");
//                String num = result.getNString("num");
//                float solde = result.getFloat("solde");
//                System.out.println("id " + id + " num : " + num + " solde : " + solde);
//            }
//            // compter les interblocages et autres et relancé si procédure rejeté
//        } catch (Exception e) {
//            System.out.println("Erreur : " + e.getMessage());
//        }
//    }

    public static void main(String[] args) {

        TransfertMultiple transfert1 = new TransfertMultiple("U1");
        Thread t1 = transfert1.demarrer("1", "2", 50, 100, "transferer1");
        
        TransfertMultiple transfert2 = new TransfertMultiple("U2");
        Thread t2 = transfert2.demarrer("2", "1", 0, 100, "transferer1");
        
        System.out.println("Transferring money...");
        
        if (t1 != null && t2 != null) {
           try {
              t1.join();
              t2.join();
              
              System.out.println("Finished transferring...");
           } catch (InterruptedException ex) {
              Logger.getLogger(MAC_labo2_part2.class.getName()).log(Level.SEVERE, null, ex);
           }
        }

        System.exit(0);
    }
    
    /*
    Liste des opérations possibles 
    
    Procédures :
    lire_etat_compte(id_compte INT)
    deposer_sur_compte (id_compte INT, montant FLOAT)
    transferer1(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
    transferer2(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
    transferer3(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
    transferer4(cpt1 VARCHAR(30), cpt2 VARCHAR(30), montant FLOAT)
    
    Fonctions :
    has_write_acces(id_compte INT)
    has_read_acces(id_compte INT)
    get_user_id ()
    get_user_compte_acces (id_compte INT)
    */

}
