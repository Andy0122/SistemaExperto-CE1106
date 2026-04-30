% ==============================================================================
% Archivo: Logic.pl
% Módulo: Motor de Inferencia (Sistema Experto)
% Descripción: Recibe las intenciones (si/no) y los atributos extraídos por 
% el analizador sintáctico y los evalúa contra la base de datos (hechos) 
% para encontrar la profesión más adecuada mediante backtracking.
% ==============================================================================

:- consult('BD.pl').
:- consult('BNF.pl').

% ------------------------------------------------------------------------------
% UTILIDADES DE MANEJO DE LISTAS
% ------------------------------------------------------------------------------

% Verifica si al menos un elemento de la primera lista existe en la segunda.
interseccion_lista([H|_], Lista2) :- member(H, Lista2), !.
interseccion_lista([_|T], Lista2) :- interseccion_lista(T, Lista2).

% Cuenta cuántos elementos en común tienen dos listas (para calificar el match).
contar_coincidencias([], _, 0).
contar_coincidencias([H|T], Lista2, N) :-
    member(H, Lista2), !,
    contar_coincidencias(T, Lista2, N1),
    N is N1 + 1.
contar_coincidencias([_|T], Lista2, N) :-
    contar_coincidencias(T, Lista2, N).

% ------------------------------------------------------------------------------
% EVALUACIÓN DEL PERFIL DEL USUARIO
% Acumula los gustos (intención: si) y rechazos (intención: no) detectados.
% ------------------------------------------------------------------------------

% Predicado para procesar la entrada y actualizar el perfil temporal
% evalua_perfil(+Intencion, +Atributos, +GustosActuales, +RechazosActuales, -NuevosGustos, -NuevosRechazos)
evalua_perfil(si, Atributos, GustosIn, RechazosIn, GustosOut, RechazosIn) :-
    append(GustosIn, Atributos, GustosOut).

evalua_perfil(no, Atributos, GustosIn, RechazosIn, GustosIn, RechazosOut) :-
    append(RechazosIn, Atributos, RechazosOut).

% ------------------------------------------------------------------------------
% REGLA PRINCIPAL DEL SISTEMA EXPERTO
% recomendar_carrera(+GustosUsuario, +RechazosUsuario, -CarreraRecomendada)
% Ejecuta el motor lógico cruzando restricciones con la Base de Datos.
% ------------------------------------------------------------------------------
recomendar_carrera(GustosUsuario, RechazosUsuario, CarreraRecomendada) :-
    % 1. Extrae una profesión de la BD
    profesion(CarreraRecomendada, Afinidades, Fortalezas, AntagoniasCarrera),
    
    % 2. Une Afinidades y Fortalezas para hacer el perfil completo de la carrera
    append(Afinidades, Fortalezas, PerfilCarrera),
    
    % RESTRICCIÓN LÓGICA 1: El usuario NO debe detestar lo que la carrera exige
    \+ interseccion_lista(RechazosUsuario, PerfilCarrera),
    
    % RESTRICCIÓN LÓGICA 2: El usuario NO debe gustarle lo que la carrera rechaza
    \+ interseccion_lista(GustosUsuario, AntagoniasCarrera),
    
    % CONDICIÓN DE ÉXITO: Debe haber afinidad comprobada
    contar_coincidencias(GustosUsuario, PerfilCarrera, Coincidencias),
    Coincidencias > 0.