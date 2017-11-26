package mac_labo2_part2;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 */
public class TransfertMultiple {

   // Username and password to use to connect to the DB
   private final String username;
   private final String password;

   // DB connection
   private Connection conSQL;
   
   private PreparedStatement transferStatement;

   /**
    * Create a TransferMultiple instance for the given username and password
    *
    * @param username the username to use for the transactions
    * @param password the password to use for the transactions
    */
   public TransfertMultiple(String username, String password) {
      this.username = username;
      this.password = password;
   }

   /**
    * Create a TransferMultiple instance for the given username. The user
    * password will be the same as the username
    *
    * @param username the username to use
    */
   public TransfertMultiple(String username) {
      this(username, username);
   }

   /**
    * Start the transfers in a new Thread.
    *
    * @param account1 the account withdraw some money from
    * @param account2 the account to transfer the money to
    * @param amount the amount of money to transfer
    * @param nbOfTransferts the number of transfer to do
    * @param procedure the procedure to use
    * @return the thread in which the transfers are being executed
    */
   public Thread demarrer(String account1, String account2, int amount,
           int nbOfTransferts, String procedure) {
      // Connect to the DB using the username and password
      try {
         // Get a connection to the DB
         Class.forName("com.mysql.jdbc.Driver");
         conSQL = DriverManager.getConnection("jdbc:mysql://localhost/transactions", username, password);

         // Prepare the statement
         final String TRANSFER_STATEMENT = "CALL " + procedure + "(?, ?, ?);";
         transferStatement = conSQL.prepareStatement(TRANSFER_STATEMENT);
         
         Thread executionThread = new Thread(new Runnable() {
            @Override
            public void run() {
               for (int i = 0; i < nbOfTransferts; ++i) {
                  try {
                     // TODO démarrer un Runnable
                     transferStatement.setString(1, account1);
                     transferStatement.setString(2, account2);
                     transferStatement.setInt(3, amount);
                     transferStatement.executeQuery();

                     // TODO faire 2000 transactions
                  } catch (SQLException ex) {
                     // The transaction failed, do it again
                     System.out.println("Erreur : " + ex.getMessage());
                  }
               }
            }
         });
         
         executionThread.start();
         
         return executionThread;
         
      } catch (Exception e) {
         System.out.println("Erreur : " + e.getMessage());
      }
      
      return null;
   }
   
   public void deposerSurCompte(int cpt, float montant) {
      try {
         PreparedStatement depositStatement = conSQL.prepareStatement("call deposer_sur_compte(?,?);");
         depositStatement.setInt(1, cpt);
         depositStatement.setFloat(2, montant);
         depositStatement.executeQuery();
      } catch (Exception e) {
         System.out.println("Erreur : " + e.getMessage());
      }
   }
}
