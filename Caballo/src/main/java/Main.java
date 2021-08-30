import java.io.IOException;
import java.util.Scanner;

public class Main {
    static int [][] tablero = new int[8][8];
    static int estoyEn =0;
    static Scanner scannerString = new Scanner(System.in);
    //{2,1},{2,-1},{-2,1},{-2,-1},{-1,2},{-1,-2},{1,2},{1,-2}

    public static void main(String[] args) throws IOException {

        System.out.println("El tablero esta vacio: ");

        for(int i =0; i<8; i++){
            for(int j=0; j<8;j++){
                System.out.printf("%d   ",tablero[i][j]);

            }
            System.out.printf("\n");
        }

        System.out.println("Presione la tecla S para continuar");
        String rta = scannerString.nextLine();

        if(rta.equalsIgnoreCase("s")){

            if(Main.moverCaballo(0,0)){

                for(int i =0; i<8; i++){
                    for(int j=0; j<8;j++){
                        System.out.printf("%d   ",tablero[i][j]);

                    }
                    System.out.printf("\n");
                }
            }else{
                System.out.println("no encontre una mierda");
            }
        }else{
            System.out.println("te curtis trolo");
        }
    }

    public static boolean moverCaballo(int fila, int columna){

        if(!Main.estaVacio(fila,columna)){
            return false;
        }
        estoyEn++;
        tablero[fila][columna]=estoyEn;

        if(estoyEn == 64){
            return true;
        }

        if(estaDentroTablero(fila+2,columna+1) && moverCaballo(fila+2,columna+1))
            return true;
        if(estaDentroTablero(fila+2,columna-1) && moverCaballo(fila+2,columna-1))
            return true;
        if(estaDentroTablero(fila-2,columna+1) && moverCaballo(fila-2,columna+1))
            return true;
        if(estaDentroTablero(fila-2,columna-1) && moverCaballo(fila-2,columna-1))
            return true;
        if(estaDentroTablero(fila+1,columna+2) && moverCaballo(fila+1,columna+2))
            return true;
        if(estaDentroTablero(fila+1,columna-2) && moverCaballo(fila+1,columna-2))
            return true;
        if(estaDentroTablero(fila-1,columna+2) && moverCaballo(fila-1,columna+2))
            return true;
        if(estaDentroTablero(fila-1,columna-2) && moverCaballo(fila-1,columna-2))
            return true;


        return false;
    }

    public static boolean estaVacio(int fila, int columna){
        return tablero[fila][columna] == 0;
    }

    public static boolean estaDentroTablero(int fila, int columna){
        return fila <8 && columna<8 && columna>=0 && fila >=0;

    }
}
