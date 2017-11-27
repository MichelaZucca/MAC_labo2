/**
 * File: TransfertMultiple.java
 * 
 * MAC Labo 2 - partie 2
 * Programme de test d'accès à la base de données
 * Mathieu Monteverde, Sathyia Kirushnapillai et Michela Zucca
 */

package mac_labo2_part2;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * La class TransfertMultiple permet d'effectuer des tests de transferts multiples
 * d'un compte à l'autre sur la base de données Transactions. 
 * 
 * L'instance ouvre une connection SQL en utilisant JDBC dans son constructeur
 * et lance les tests dans un nouveau Thread lorsqu'on appelle la méthode démarrer.
 * On peut ensuite récupérer le nombre d'interblocages qui ont eu lieu ainsi 
 * que le temps que cela a pris pour effectuer l'intégralité du test.
 * 
 * La classe offre également certaines méthodes pour effectuer des actions en DB 
 * qui n'ont pas forcèment de lien avec les tests, mais qui ont été ajouté 
 * dans cette classe par commodité. 
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

   public static long MAX_DEADLOCK = 6000;

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
      conSQL = DriverManager.getConnection("jdbc:mysql://localhost/Transactions", username, password);
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
    * Démarre le test dans un nouveau thread. 
    * 
    * Le test va appeler nbOfTransfers fois la procédure spécifiée en paramètre
    * et calculer le nombre d'interblocages qui ont lieu ainsi que le temps
    * d'exécution du test. 
    *
    * @param account1 the account to withdraw some money from
    * @param account2 the account to transfer the money to
    * @param amount the amount of money to transfer
    * @param nbOfTransfers the number of transfer to do
    * @param procedure the procedure to use
    * @return the thread in which the transfers are being executed
    */
   public Thread demarrer(String account1, String account2, int amount,
           int nbOfTransfers, String procedure) {
      // Connect to the DB using the username and password
      try {

         // Prepare the statement
         final String TRANSFER_STATEMENT = "CALL " + procedure + "(?, ?, ?);";
         transferStatement = conSQL.prepareStatement(TRANSFER_STATEMENT);
         transferStatement.setString(1, account1);
         transferStatement.setString(2, account2);
         transferStatement.setInt(3, amount);

         Thread executionThread = new Thread(new Runnable() {
            @Override
            public void run() {
               // Start time
               long start = System.currentTimeMillis();
               
               // Do all transfers
               for (int i = 0; i < nbOfTransfers; ++i) {
                  try {
                     transferStatement.executeQuery();
                  } catch (SQLException ex) {
                     // If the cause of the exception was a deadlock
                     if (ex.getSQLState().equals("40001")) {
                        
                        // The transaction failed, do it again and increase the deadlock count
                        ++deadlockCount;
                        --i;

                        // We stop if the number of deadlocks is being excessive
                        if (deadlockCount > MAX_DEADLOCK) {
                           break;
                        }
                     }
                  }
               }
               // End time
               long end = System.currentTimeMillis();
               
               // Calculate execution time 
               executionTime = end - start;
            }
         });
         
         // Start the thread
         executionThread.start();
         
         // Return the thread
         return executionThread;
      } catch (Exception e) {
         System.out.println("Erreur : " + e.getMessage());
      }

      return null;
   }
   
   /**
    * Reset the amount of money on all accounts. It loads 500 on each row of the 
    * comptes database.
    */
   public void resetAccounts() {
      try {
         PreparedStatement resetStatement = 
                 conSQL.prepareStatement("UPDATE comptes SET solde = 500;");
         resetStatement.execute();
      } catch (SQLException ex) {
         Logger.getLogger(TransfertMultiple.class.getName()).log(Level.SEVERE, null, ex);
      }
   }

   /**
    * Display all account states. The user must be able to execute queries.
    */
   public void displayAccountsState() {
      try {
         // SQL Statement
         PreparedStatement statement = conSQL.prepareStatement("SELECT * FROM comptes");
         ResultSet result = statement.executeQuery();
         
         // Display results
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

   /**
    * Set the isolation mode for the current session. 
    * @param isolationMode a String containing the SQL isolation mode to use
    */
   public void setIsolationMode(String isolationMode) {
      // Prepare the statement
      final String ISOLATION = "SET SESSION TRANSACTION ISOLATION LEVEL " + isolationMode;
      
      try {
         // Execute the query
         PreparedStatement isolationStatement = conSQL.prepareStatement(ISOLATION);
         isolationStatement.executeQuery();
         
         // Get the modified state from the DB and display the information
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
   
   /**
    * Close the SQL connection
    * @throws SQLException if something goes wrong
    */
   public void closeConnection() throws SQLException {
      conSQL.close();
   }
   
   /**
    * Get the number of deadlock that occurred during the execution
    * @return 
    */
   public long getDeadlockCount() {
      return deadlockCount;
   }

   /**
    * Get the time of the execution
    * @return the time of execution in ms
    */
   public long getExecutionTime() {
      return executionTime;
   }
}
