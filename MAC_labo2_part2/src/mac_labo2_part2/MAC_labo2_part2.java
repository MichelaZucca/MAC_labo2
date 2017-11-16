/**
 * MAC Labo 2 - partie 2
 * Programme de test d'accès à la base de données
 * Mathieu Monteverde, Sathyia Kirushnapillai et Michela Zucca
 */
package mac_labo2_part2;

import java.sql.*;
import java.time.temporal.IsoFields;

class User {

    private Connection conSql;
    private Statement statement;
    private String name;
    private boolean isFinish = false;

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
        isFinish = false;
     /*   Thread thread = new Thread() {
            @Override
            public void run() {*/
                while (!isFinish) {
                    for (int i = 0; i < nbTransaction; i++) {
                        System.out.println("User : " + name + " i: " + i);
                        try {
                            // TODO appel de la procédure choisie
                            statement.executeQuery(req);
                            // compter les interblocages et autres et relancé si procédure rejeté
                        } catch (Exception e) {
                            System.out.println("Erreur requete : " + e.getMessage());
                        }
                    }
                    isFinish = true;
                }
       /*     }
        };
        thread.start();*/
    }

    public boolean isFinish() {
        return isFinish;
    }

    public void deposerSurCompte(int cpt, float montant) {
        try {
            statement.executeQuery("call deposer_sur_compte(1," + montant + ")");
        } catch (Exception e) {
            System.out.println("Erreur : " + e.getMessage());
        }
    }

    public void etatComptes() {
        try {
            // TODO appel de la procédure choisie
            ResultSet result = statement.executeQuery("Select * from comptes");
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
}

public class MAC_labo2_part2 {

    public static void main(String[] args) {

        String transferer1 = "transferer1";
        String transferer2 = "transferer2";
        String transferer3 = "transferer3";
        String transferer4 = "transferer4";

        User u1 = new User("U1");
        User u2 = new User("U2");
        User root = new User("root");

        root.connextionToDB();
        u1.connextionToDB();
        u2.connextionToDB();

        // cpt1, cpt2, montant, nb, procedure
        u1.demarrer("1", "2", 20, 10, transferer1);
        u2.demarrer("2", "1", 10, 10, transferer1);

        System.exit(0);
    }

}
