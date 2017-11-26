package mac_labo2_part2;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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

   // Prepared transfert...
   private PreparedStatement transferStatement;

   // Statistic values
   private long deadlockCount;

   // execution time
   private long executionTime;

   public static long MAX_DEADLOCK = 2000;

   /**
    * Create a TransferMultiple instance for the given username and password
    *
    * @param username the username to use for the transactions
    * @param password the password to use for the transactions
    */
   public TransfertMultiple(String username, String password) throws ClassNotFoundException, SQLException {
      this.username = username;
      this.password = password;

      // Get a connection to the DB
      Class.forName("com.mysql.jdbc.Driver");
      conSQL = DriverManager.getConnection("jdbc:mysql://localhost/transactions", username, password);
   }

   /**
    * Create a TransferMultiple instance for the given username. The user
    * password will be the same as the username
    *
    * @param username the username to use
    * @throws java.lang.ClassNotFoundException
    * @throws java.sql.SQLException
    */
   public TransfertMultiple(String username) throws ClassNotFoundException, SQLException {
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

         // Prepare the statement
         final String TRANSFER_STATEMENT = "CALL " + procedure + "(?, ?, ?);";
         transferStatement = conSQL.prepareStatement(TRANSFER_STATEMENT);

         Thread executionThread = new Thread(new Runnable() {
            @Override
            public void run() {
               long start = System.currentTimeMillis();
               for (int i = 0; i < nbOfTransferts; ++i) {
                  try {
                     transferStatement.setString(1, account1);
                     transferStatement.setString(2, account2);
                     transferStatement.setInt(3, amount);
                     transferStatement.executeQuery();
                  } catch (SQLException ex) {
                     // The transaction failed, do it again
                     ++deadlockCount;
                     --i;

                     // We stop if the number of deadlocks is being excessive
                     if (deadlockCount > MAX_DEADLOCK) {
                        break;
                     }
                  }
               }
               long end = System.currentTimeMillis();

               executionTime = end - start;
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
   
   public void resetComptes() {
      try {
         PreparedStatement resetStatement = conSQL.prepareStatement("UPDATE comptes SET solde = 500;");
         resetStatement.execute();
      } catch (SQLException ex) {
         Logger.getLogger(TransfertMultiple.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   public void etatComptes() {
      try {
         PreparedStatement statement = conSQL.prepareStatement("Select * from comptes");
         ResultSet result = statement.executeQuery();

         while (result.next()) {
            int id = result.getByte("id");
            String num = result.getNString("num");
            float solde = result.getFloat("solde");
            System.out.println("id " + id + " num : " + num + " solde : " + solde);
         }
         // compter les interblocages et autres et relancé si procédure rejeté
      } catch (Exception e) {
         System.out.println("Erreur : " + e.getMessage());
      }
   }

   public void setIsolationMode(String isolationMode) {
      final String ISOLATION = "SET SESSION TRANSACTION ISOLATION LEVEL " + isolationMode;
      try {
         PreparedStatement isolationStatement = conSQL.prepareStatement(ISOLATION);
         isolationStatement.executeQuery();
         
         final String ISOLATION_STATEMENT = "SELECT @@tx_isolation";
         PreparedStatement getIsolationStatement = conSQL.prepareStatement(ISOLATION_STATEMENT);
         
         ResultSet result = getIsolationStatement.executeQuery();
         
         while (result.next()) {
            String isolation = result.getString("@@tx_isolation");
            System.out.println("Isolation mode was set to " + isolation);
         }
         
      } catch (SQLException ex) {
         Logger.getLogger(TransfertMultiple.class.getName()).log(Level.SEVERE, null, ex);
      }

   }

   public void closeConnection() throws SQLException {
      conSQL.close();
   }

   public long getDeadlockCount() {
      return deadlockCount;
   }

   public long getExecutionTime() {
      return executionTime;
   }
}
