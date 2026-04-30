% ===================================================================
% Archivo: Logic.pl
% ===================================================================

:- consult('BD.pl').
:- consult('BNF.pl').

% ===================================================================
% MODO DE PRUEBA TEMPORAL (Solo para probar el BNF)
% ===================================================================
iniciar :-
    writeln('======================================================='),
    writeln('  MODO DE PRUEBA DEL ANALIZADOR SINTACTICO (BNF)       '),
    writeln('  Escribe oraciones para ver si son Positivas o Negativas.'),
    writeln('  Escribe "salir" para terminar la prueba.             '),
    writeln('======================================================='),
    ciclo_prueba.

ciclo_prueba :-
    write('\nUsuario: '),
    read_line_to_string(user_input, Entrada),
    string_lower(Entrada, EntradaMin),
    
    ( EntradaMin == "salir" ->
        writeln('\nOrientadorCE: Terminando modo de prueba. ¡Nos vemos!')
    ;
        procesar_oracion(Entrada, Intencion, Atributos),
        
        format('   -> [BNF RESPONDE] Intencion: ~w | Palabras detectadas: ~w~n', [Intencion, Atributos]),
        
        ciclo_prueba
    ).