% ==============================================================================
% Archivo: BD.pl
% Módulo: Base de Datos (Hechos)
% Descripción: Contiene el catálogo de profesiones del sistema experto. 
% Cada profesión está definida por las características que requiere 
% (afinidades y fortalezas) y las características que rechaza (antagonias).
% ==============================================================================

% ------------------------------------------------------------------------------
% ESTRUCTURA DE LA BASE DE DATOS
% profesion(NombreCarrera, [ListaDeAfinidades], [ListaDeFortalezas], [ListaDeAntagonias]).
% Nota: Los atributos utilizados aquí deben coincidir con los definidos en 
% el predicado es_atributo/1 de BNF.pl.
% ------------------------------------------------------------------------------

% 1. Ingeniería en Computadores
profesion(ingenieria_computadores, [tecnologia, maquinas, compu], [matematicas, problemas, calculo], [rutina, naturaleza]).

% 2. Psicología
profesion(psicologia, [personas, gente, humanos], [escuchar, hablar], [aislamiento, problemas_matematicos]).

% 3. Medicina
profesion(medicina, [ciencia, personas, humanos], [investigacion, trabajar_bajo_presion], [rutina, poco_estudio]).

% 4. Arquitectura
profesion(arquitectura, [diseno, casa, hogar], [arte, dibujo, matematicas], [rutina]).

% 5. Derecho
profesion(derecho, [personas, publico], [hablar, leer, memoria], [timidez, matematicas]).

% 6. Administración de Empresas
profesion(administracion, [personas, publico, oficina], [numeros, organizacion], [desorden, arte]).

% 7. Diseño Gráfico
profesion(diseno_grafico, [arte, diseno, creatividad], [dibujo, tecnologia, compu], [rutina, matematicas, calculo]).

% 8. Biología
profesion(biologia, [ciencia, naturaleza, animales], [investigacion, exteriores, plantas], [oficina, rutina]).

% 9. Periodismo
profesion(periodismo, [personas, gente, publico], [hablar, escribir, investigacion], [timidez, oficina]).

% 10. Educación
profesion(educacion, [personas, gente, humanos], [ensenar, hablar, paciencia], [aislamiento, poca_paciencia]).