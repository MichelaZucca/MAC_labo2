/**
 * MAC Labo 2 - partie 2
 * Programme de test d'accès à la base de données
 * Mathieu Monteverde, Sathyia Kirushnapillai et Michela Zucca
 */
package mac_labo2_part2;

import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Ce programme principal effectue des tests des procédures stockées
 * transferer1, transferer2, transferer3 et transferer4 dans les différents
 * modes d'isolation comme demandé pour le laboratoire.
 * 
 * Il affiche ensuite les résultats dans la console.
 */
public class MAC_labo2_part2 {
   
   /**
    * Effectuer le test de la procédure fournie en mode d'isolation founi.
    * 
    * Cette méthode va créer des instances de la classe TransfertMultiple pour
    * le user U1 et U2. Elle va aussi utiliser une instance TransfertMultiple pour
    * l'utilisateur root, mais simplement pour donner un solde de départ à tous
    * les comptes au début du test et pour afficher l'état des comptes. 
    * 
    * @param procedure le nom de la procédure a appeler.
    * @param isolationMode le mode d'isolation à utiliser
    */
   public static void transferTest(String procedure, String isolationMode) {

      try {
         // Create the two TransfertMultiple instances and the root access
         TransfertMultiple transfert1 = new TransfertMultiple("U1");
         TransfertMultiple transfert2 = new TransfertMultiple("U2");
         TransfertMultiple adminAccess = new TransfertMultiple("admin");
         
         // Show the current procedure
         System.out.println("==================================");
         System.out.println(procedure + " in mode " + isolationMode);
         System.out.println("==================================");

         // Reset the accounts
         adminAccess.resetComptes();
         System.out.println("Etat des comptes avant l'expérience: ");
         adminAccess.etatComptes();

         // Set the isolation mode for the two working objects
         transfert1.setIsolationMode(isolationMode);
         transfert2.setIsolationMode(isolationMode);

         // Do the test
         Thread t1 = transfert1.demarrer("1", "2", 50, 2000, procedure);
         Thread t2 = transfert2.demarrer("2", "1", 50, 2000, procedure);

         System.out.println("Transferring money...");

         if (t1 != null && t2 != null) {
            try {
               
               // Wait for the end of the test
               t1.join();
               t2.join();

               // TODO output the results
               System.out.println("Finished transferring...");

               System.out.println("Etat des comptes...");
               adminAccess.etatComptes();

               System.out.println("");
               System.out.println("U1:");
               System.out.println("Interblocages: " + transfert1.getDeadlockCount());
               System.out.println("Temps d'exécution: " + transfert1.getExecutionTime());

               System.out.println("");
               System.out.println("U2:");
               System.out.println("Interblocages: " + transfert2.getDeadlockCount());
               System.out.println("Temps d'exécution: " + transfert2.getExecutionTime());

               // Close all connections
               transfert1.closeConnection();
               transfert2.closeConnection();
               adminAccess.closeConnection();
            } catch (InterruptedException ex) {
               Logger.getLogger(MAC_labo2_part2.class.getName()).log(Level.SEVERE, null, ex);
            } catch (SQLException ex) {
               Logger.getLogger(MAC_labo2_part2.class.getName()).log(Level.SEVERE, null, ex);
            }
         }

      } catch (ClassNotFoundException ex) {
         Logger.getLogger(MAC_labo2_part2.class.getName()).log(Level.SEVERE, null, ex);
      } catch (SQLException ex) {
         Logger.getLogger(MAC_labo2_part2.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   public static void main(String[] args) {

      String[] procedures = {"transferer2", "transferer3", "transferer4"};

      transferTest("transferer1", "REPEATABLE READ");

      for (int i = 0; i < procedures.length; ++i) {
         transferTest(procedures[i], "REPEATABLE READ");
         transferTest(procedures[i], "READ COMMITTED");
         transferTest(procedures[i], "READ UNCOMMITTED");
         transferTest(procedures[i], "SERIALIZABLE");
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
