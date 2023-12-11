PAV - P4: reconocimiento y verificación del locutor
===================================================

Obtenga su copia del repositorio de la práctica accediendo a [Práctica 4](https://github.com/albino-pav/P4)
y pulsando sobre el botón `Fork` situado en la esquina superior derecha. A continuación, siga las
instrucciones de la [Práctica 2](https://github.com/albino-pav/P2) para crear una rama con el apellido de
los integrantes del grupo de prácticas, dar de alta al resto de integrantes como colaboradores del proyecto
y crear la copias locales del repositorio.

También debe descomprimir, en el directorio `PAV/P4`, el fichero [db_8mu.tgz](https://atenea.upc.edu/mod/resource/view.php?id=3654387?forcedownload=1)
con la base de datos oral que se utilizará en la parte experimental de la práctica.

Como entrega deberá realizar un *pull request* con el contenido de su copia del repositorio. Recuerde
que los ficheros entregados deberán estar en condiciones de ser ejecutados con sólo ejecutar:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
  make release
  run_spkid mfcc train test classerr verify verifyerr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recuerde que, además de los trabajos indicados en esta parte básica, también deberá realizar un proyecto
de ampliación, del cual deberá subir una memoria explicativa a Atenea y los ficheros correspondientes al
repositorio de la práctica.

A modo de memoria de la parte básica, complete, en este mismo documento y usando el formato *markdown*, los
ejercicios indicados.

## Ejercicios.

### SPTK, Sox y los scripts de extracción de características.

- Analice el script `wav2lp.sh` y explique la misión de los distintos comandos involucrados en el *pipeline*
  principal (`sox`, `$X2X`, `$FRAME`, `$WINDOW` y `$LPC`). Explique el significado de cada una de las 
  opciones empleadas y de sus valores.

  El script `wav2lp.sh` se encarga de obtener los coeficientes de predicción lineal (LPC) de una señal de audio en concreto. Para ello hace uso de los programas `SoX` y `SPTK`      (Speech Signal Processing Toolkit).

  En primer lugar, podemos ver como el script requiere de una señal de entrada de tipo *wav* y nos devuelve un archivo de tipo *lp*:
  
  <img width="313" alt="Captura de pantalla 2023-12-04 a las 12 00 01" src="https://github.com/nareshmarques/P4/assets/118903051/d6136efe-85f0-4739-914a-27fbd7fbc660">

  A continuación podemos observar la definición de los parámetros que el usuario deberá introducir al invocar el script: número de coeficientes de predicción lineal, fichero de     entrada y fichero de salida. Una vez introducidos éstos se guardarán en sus variables correspondientes:

  <img width="443" alt="Captura de pantalla 2023-12-04 a las 12 05 28" src="https://github.com/nareshmarques/P4/assets/118903051/092849f0-9b96-4255-b8ee-e1f53cc3fd7c">

  Cabe destacar también que al usar `SPTK`, si se dispone de un ordenador con *Ubuntu*, los comandos deberán llevar el prefijo *sptk*, mientras que en ordenadores Apple no será     necesario. 

  Seguidamente, repasaremos los comandos empleados en el script y las opciones que hemos escogido:

  - `sox` : Editar ficheros de audio
    * -t : Tipo de fichero de audio [*raw*]
    * -e : Codificación del fichero [signed]
    * -b : Tamaño de trama en bits [16 bits]
    *  - : Redirección del output (*pipeline*)
        
  - `$X2X` : Convertir datos a distintos formatos
    * +sf : short (2  bytes) --> float (4 bytes)
      
  - `$FRAME` : Entramar la señal de entrada en distintas tramas con periodo P y longitud L. Puede haber solapamiento
    * -l : Número de muestras de cada trama (longitud) [240 muestras = 30ms]
    * -p : Período de cada trama, o muestras de desplazamiento entre tramas [80 muestras = 10ms]

  - `$WINDOW` : Multiplicar cada trama por una ventana, por defecto la de Blackman
    * -l : Longitud,en muestras, de la ventana de entrada [240 muestras]
    * -L : Longitud, en muestras, de la ventana de salida [240 muestras]
 
  - `$LPC` : Calcular los coeficientes de predicción lineal, precedidos por el factor de ganancia del predictor
    * -l : Longitud, en muestras, de la ventana de entrada [240 muestras]
    * -m : Número de coeficientes del LPC [lo determinamos en base a su orden]

- Explique el procedimiento seguido para obtener un fichero de formato *fmatrix* a partir de los ficheros de
  salida de SPTK (líneas 45 a 51 del script `wav2lp.sh`).

  <img width="588" alt="Captura de pantalla 2023-12-04 a las 12 40 11" src="https://github.com/nareshmarques/P4/assets/118903051/2afdfe1a-6d46-40eb-b6ae-70d21fd611dc">

  El formato de las señales parametrizadas empleado, *fmatrix*, almacena los datos en *nrow* filas y *ncol* columnas, en los que cada fila corresponde a una trama de señal y cada   columna a cada uno de los coeficientes con los que se parametriza la trama.
  
  Para obtener el número de columnas, hemos de sumarle 1 al orden de predicción, ya que el primer valor se corresponde a la ganancia. Si queremos ahora obtener el número de         filas, éste se obtendrá usando el comando `perl`. Inicialmente tenemos un conjunto de floats de 4 bytes, para poder realizar el cálculo hacemos una transformación y los pasamos   a ASCII, de modo que se genera un fichero con los valores ASCII, uno en cada fila. A través del comando `wc` *-l* obtenemos el número de filas.

  * ¿Por qué es más conveniente el formato *fmatrix* que el SPTK?

  El formato *fmatrix* nos permite guardar los datos de manera más ordenada, porqué tenemos las señales organizadas por tramas y coeficientes de modo que en cada fila de la         matriz hay una trama de la señal y en cada columna se encuentra uno de los coeficientes con los que hemos parametrizado dicha trama. Cabe destacar también que de una matriz       podemos seleccionar las filas o columnas que nos interesen de manera fàcil con la función *cut*, hecho que facilita la interpretación de los resultados.

- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales de predicción lineal
  (LPCC) en su fichero <code>scripts/wav2lpcc.sh</code>:
  
  <img width="723" alt="Captura de pantalla 2023-12-04 a las 16 56 30" src="https://github.com/nareshmarques/P4/assets/118903051/aa1d8295-f90c-4803-9f3e-d68c4634521f">

- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales en escala Mel (MFCC) en su
  fichero <code>scripts/wav2mfcc.sh</code>:
  
  <img width="725" alt="image" src="https://github.com/nareshmarques/P4/assets/118903051/4b9de2a9-920a-444e-b1b0-733381a16cac">



### Extracción de características.

- Inserte una imagen mostrando la dependencia entre los coeficientes 2 y 3 de las tres parametrizaciones
  para todas las señales de un locutor.
  
  + Indique **todas** las órdenes necesarias para obtener las gráficas a partir de las señales 
    parametrizadas.
    
    En primer lugar, parametrizamos las distintas señales tanto para LP, LPCC y MFCC utilizando el script `run_spkid`:

      `FEAT=lp run_spkid lp`  `FEAT=lpcc run_spkid lpcc` `FEAT=mfcc run_spkid mfcc`
    
    A continuación, escogiendo las parametrizaciones de *work/lp/BLOCK01/SES017*, convertimos a texto sus coeficientes 2 y 3:

    <img width="1001" alt="Captura de pantalla 2023-12-11 a las 14 44 31" src="https://github.com/nareshmarques/P4/assets/118903051/ccdf84dd-a601-4e59-9953-740378884558">

    Finalmente, empleamos el siguiente script de Matlab para representar las gráficas a partir de los ficheros de texto:

    ```Matlab
    %LP

    datos_lp = load('lp_2_3.txt');
    coef_2_lp = datos_lp(:,1);
    coef_3_lp = datos_lp(:,2);
    sz=5;
    
    subplot(3,1,1);
    scatter(coef_2_lp, coef_3_lp, sz, 'filled', 'MarkerEdgeColor',[0 .5 .5],'MarkerFaceColor',[0 .7 .7],'LineWidth',0.5);
    title('Parametrización LP')
    xlabel('Coeficiente 2')
    ylabel('Coeficiente 3')
    grid on

    %LPCC

    datos_lpcc = load('lpcc_2_3.txt');
    coef_2_lpcc = datos_lpcc(:,1);
    coef_3_lpcc = datos_lpcc(:,2);
    sz=5;
    
    subplot(3,1,2);
    scatter(coef_2_lpcc, coef_3_lpcc, sz, 'filled','MarkerEdgeColor',[.3 0 .5],'MarkerFaceColor',[.3 0 .7],'LineWidth',0.5);
    title('Parametrización LPCC')
    xlabel('Coeficiente 2')
    ylabel('Coeficiente 3')
    grid on

    %MFCC

    datos_mfcc = load('mfcc_2_3.txt');
    coef_2_mfcc = datos_mfcc(:,1);
    coef_3_mfcc = datos_mfcc(:,2);
    sz=5;
    
    subplot(3,1,3);
    scatter(coef_2_mfcc, coef_3_mfcc, sz, 'filled', 'MarkerEdgeColor',[.5 .2 0],'MarkerFaceColor',[.7 .2 0],'LineWidth',0.5);
    title('Parametrización MFCC')
    xlabel('Coeficiente 2')
    ylabel('Coeficiente 3')
    grid on
    ```

    Hemos obtenido las siguientes gráficas de la dependencia entre los coeficientes 2 y 3 de cada parametrización:

    <img width="1187" alt="image" src="https://github.com/nareshmarques/P4/assets/118903051/d884d4df-ff1f-458c-b9a4-0493b290b523">


  + ¿Cuál de ellas le parece que contiene más información?
 
    Se obtiene mayor información de aquella gráfica en la que sus coeficientes esten más incorrelados entre ellos. En nuestro caso podemos ver como en el caso de LPCC y MFCC,
    ambos tienen una distribución más dispersa, aunque se puede observar menos correlación entre coeficientes en el caso de MFCC

- Usando el programa <code>pearson</code>, obtenga los coeficientes de correlación normalizada entre los
  parámetros 2 y 3 para un locutor, y rellene la tabla siguiente con los valores obtenidos.

  Empleamos los comandos siguientes para obtener los coeficientes 2 y 3 de cada parametrización (LP, LPC, MFCC):

  <img width="848" alt="Captura de pantalla 2023-12-11 a las 18 45 12" src="https://github.com/nareshmarques/P4/assets/118903051/35a65dba-d9c1-4454-98dc-27213ca4a17d">

  |                        |     LP    |   LPCC   |    MFCC   |
  |------------------------|:---------:|:--------:|:---------:|
  | &rho;<sub>x</sub>[2,3] | -0.872284 | 0.150782 | -0.146628 |
  
  + Compare los resultados de <code>pearson</code> con los obtenidos gráficamente.
 
  Los valores obtenidos para &rho;<sub>x</sub>[2,3] nos indican el nivel de correlación entre los coeficientes 2 y 3, donde el que tiene una mayor correlación es aquel que tiene
  un valor que se acerca más al 1. Si nos fijamos en las tabla superior, podemos ver como (en valor absoluto) para LP obtenemos un valor más cercano a 1, por lo que éste aporta     menos información. Por otro lado, LPCC y MFCC son menores y están más cerca del 0, por lo que sus coeficientes son más incorrelados entre sí y, de este modo, podemos decir que
  aportan más información. También, podemos ver como los coeficientes MFCC son ligeramente más incorrelados que los de LPCC. Dicho esto, los resultados pearson concuerdan con los   resultados gráficosobtenidos anteriormente.
  
- Según la teoría, ¿qué parámetros considera adecuados para el cálculo de los coeficientes LPCC y MFCC?
  - LPC: 8-14 coeficientes
  - MFCC: 13 coeficientes, 24-40 filtros

### Entrenamiento y visualización de los GMM.

Complete el código necesario para entrenar modelos GMM.

- Inserte una gráfica que muestre la función de densidad de probabilidad modelada por el GMM de un locutor
  para sus dos primeros coeficientes de MFCC.

- Inserte una gráfica que permita comparar los modelos y poblaciones de dos locutores distintos (la gŕafica
  de la página 20 del enunciado puede servirle de referencia del resultado deseado). Analice la capacidad
  del modelado GMM para diferenciar las señales de uno y otro.

### Reconocimiento del locutor.

Complete el código necesario para realizar reconociminto del locutor y optimice sus parámetros.

- Inserte una tabla con la tasa de error obtenida en el reconocimiento de los locutores de la base de datos
  SPEECON usando su mejor sistema de reconocimiento para los parámetros LP, LPCC y MFCC.

### Verificación del locutor.

Complete el código necesario para realizar verificación del locutor y optimice sus parámetros.

- Inserte una tabla con el *score* obtenido con su mejor sistema de verificación del locutor en la tarea
  de verificación de SPEECON. La tabla debe incluir el umbral óptimo, el número de falsas alarmas y de
  pérdidas, y el score obtenido usando la parametrización que mejor resultado le hubiera dado en la tarea
  de reconocimiento.
 
### Test final

- Adjunte, en el repositorio de la práctica, los ficheros `class_test.log` y `verif_test.log` 
  correspondientes a la evaluación *ciega* final.

### Trabajo de ampliación.

- Recuerde enviar a Atenea un fichero en formato zip o tgz con la memoria (en formato PDF) con el trabajo 
  realizado como ampliación, así como los ficheros `class_ampl.log` y/o `verif_ampl.log`, obtenidos como 
  resultado del mismo.
