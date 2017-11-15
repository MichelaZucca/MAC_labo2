/**
 * MAC Labo 2 - partie 2
 * Programme de test d'accès à la base de données
 * Mathieu Monteverde, Sathyia Kirushnapillai et Michela Zucca
 */
package mac_labo2_part2;

import java.sql.*;

class User {

    private Connection conSql;
    private Statement statement;
    private String name;

    User(String name) {
        this.name = name;
    }

    public void connextionToDB() {
        //TODO établir la connexion
        String login = this.name;
        String mdp = this.name;
        try {
            Class.forName("com.mysql.jdbc.Driver");
            this.conSql = DriverManager.getConnection("jdbc:mysql://localhost/transactions", login, mdp);
            statement = conSql.createStatement();
        } catch (Exception e) {
            System.out.println("Erreur : " + e.getMessage());
        }
    }

    public void demarrer(
            String cpt1,
            String cpt2,
            float montant,
            int nbTransaction,
            String procedure) {

        String req = "call " + procedure + "(" + cpt1 + "," + cpt2 + "," + montant + ")";
        Thread thread = new Thread() {
            @Override
            public void run() {
                while (true) {
                    for (int i = 0; i < nbTransaction; i++) {
                        try {
                            // TODO appel de la procédure choisie
                            ResultSet result = statement.executeQuery(req);
                            // compter les interblocages et autres et relancé si procédure rejeté
                        } catch (Exception e) {
                            System.out.println("Erreur requete : " + e.getMessage());
                        }
                    }
                }
            }
        };
        thread.start();
    }

    public void etatComptes() {
        try {
            // TODO appel de la procédure choisie
            
            ResultSet result = statement.executeQuery("deposer_sur_compte(1, 300)");
            result = statement.executeQuery("call lire_etat_compte(1)");
            result = statement.executeQuery("call lire_etat_compte(2)");
            // compter les interblocages et autres et relancé si procédure rejeté
        } catch (Exception e) {

        }
    }
}

public class MAC_labo2_part2 {

    public static void main(String[] args) {

        User u1 = new User("U1");
        User u2 = new User("U2");

        User root = new User("root");
        root.connextionToDB();
        root.etatComptes();
        
        u1.connextionToDB();
    //    u1.demarrer("cpt1", "cpt2", 20, 2, "transferer1");
        root.etatComptes();
       

    }

}
