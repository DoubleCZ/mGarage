import React, { createContext, useContext, useState, useEffect, useMemo } from 'react';
import { fetchNui } from './fetchNui';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { isEnvBrowser } from './misc';

interface Lang { [key: string]: string; }

//default lang
const DevLang: Lang = {
    "GarageName": "Nombre del Garaje",
    "GarageCreateSpan": "Nombre único por garaje",
    "GarageJob": "Trabajo",
    "GarageJobSpan": "Si no escribes nada, será para todos.",
    "GarageType": "Tipo de Garaje",
    "GarageTypeSpan": "Tipo de garaje, 2 opciones: garaje o depósito",
    "GarageType1": "Garaje",
    "GarageType2": "Depósito",
    "GarageType3": "Custom",
    "GarageImpound": "Precio del Depósito",
    "GarageImpoundSpan": "Establece un precio predeterminado para recuperar vehículos de este depósito.",
    "GarageSociety": "Sociedad",
    "GarageSocietySpan": "Nombre de la sociedad a la que irán los fondos recaudados.",
    "GarageActionType": "Tipo de de Zona",
    "GarageActionTypeSpan": "TextUi / Target / Radial Menu",
    "GarageActionType1": "Target",
    "GarageActionType2": "TextUI",
    "GarageActionType3": "Radial Menu",
    "GarageNPC": "NPC Hash",
    "GarageNPCSpan": "Agrega un NPC a la zona objetivo, funciona con las coordenadas del garaje.",
    "GarageVehicleType": "Tipo de Vehículo",
    "GarageVehicleTypeSpan": "Selecciona las categorías de vehículos que se pueden estacionar.",
    "GarageDebug": "Debug",
    "GarageDebugSpan": "Visualizar la zona",
    "GarageInTocar": "Dentro del Vehículo",
    "GarageInTocarSpan": "Colocar al jugador en el vehículo al spawnear el vehículo",
    "GarageBlip": "Blip",
    "GarageBlipSpan": "Ocultar / mostrar BLIP del garaje",
    "GarageCustomCars": "Vehículos Personalizados",
    "GarageCustomCarsSpan": "Establece una lista de vehículos predeterminados, solo los vehículos generados desde este garaje pueden ser guardados.",
    "GarageRentACar": "Alquilar un Vehículo",
    "GarageRentACarSpan": "Establecer precio para alquilar un vehículo",
    "GarageSharedVehicles": "Garaje Mixto",
    "GarageSharedVehiclesSpan": "Ver todo los vehículos en propiedad del jugador.",
    "GarageDefaultImpound": "Default impound",
    "GarageDefaultImpoundSpan": "Establecer un garage [ impound ] para recuperar el vehiculo",
    "GaragePayMethod": "Metodo de pago",
    "GaragePayMethodMoney": "Efectivo",
    "GaragePayMethodBank": "Cuenta bancaria",
    "GarageButton1": "Coords",
    "GarageButton2": "Set Zone",
    "GarageButton3": "Spawn Coords",
    "GarageButton4": "Crear Garage",
    "GarageButton5": "Teleport",
    "GarageButton6": "Update",
    "GarageButton7": "Borrar",
    "GarageButton8": "Lista de garages",
    "GarageMenu1": "Precio:",
    "GarageMenu2": "Fecha:",
    "GarageMenu3": "Pagar y recuperar",
    "GarageMenu4": "Kilometros",
    "GarageMenu5": "Retirar",
    "GarageMenu6": "Llaves",
    "GarageMenu7": "GPS",
    "GarageMenu9": "Gasolina",
    "GarageMenu10": "Motor",
    "GarageMenu11": "Carroceria",
    "GarageMenu12": "GPS",
    "GarageMenu13": "Prefijo de matrícula",
    "GarageMenu14": "Establece un prefijo de máximo 4 caracteres para los vehículos generados por este garaje.",
    "GarageMenu15": "Modelo del vehículo",
    "GarageMenu16": "Precio por hora",
    "GarageMenu17": "Selecciona grados para el vehículo",
    "notYourVehicle": "Este vehículo no es tuyo...",
    "impound1": "¡Has pagado %s$ por tu vehículo!",
    "impound2": "No tienes suficiente dinero para recuperar tu vehículo",
    "impound3": "",
    "noSpawnPos": "No hay punto de aparición",
    "setBlip": "Vehículo marcado en el mapa",
    "noVehicles": "No tienes ningun vehículo en el garaje.",
    "TargetSaveCar": "Depositar vehículo",
    "TargetImpound": "Enviar al Deposito",
    "ImpoundOption1": "Incautar vehículo",
    "ImpoundOption2": "Razón",
    "ImpoundOption3": "Precio",
    "ImpoundOption4": "Establecer Fecha mínima",
    "ImpoundOption5": "Hora",
    "ImpoundOption6": "Matrícula",
    "ImpoundOption7": "Eliminar fecha de embargo de un vehículo",
    "ImpoundOption8": "Este vehículo no tiene fecha de embargo",
    "ImpoundOption9": "Este vehículo no está confiscado",
    "ImpoundOption10": "La matrícula %s no está registrada o no existe",
    "ImpoundOption11": "¡Embargo anulado!",
    "ImpoundOption12": "Podrás recuperar este vehículo",
    "ImpoundOption13": "Tiempo restante de embargo \n %s días, %s horas, %s minutos",
    "ImpoundOption14": "Incautar",
    "GarageCreate1": "mGarage CREATE",
    "GarageCreate2": "mGarage DELETE",
    "GarageCreate3": "mGarage UPDATE",
    "GarageCreate4": "Nombre [ %s ] para garaje duplicado.",
    "GarageCreate5": "Garaje %s Creado correctamente",
    "GarageCreate6": "Garaje eliminado correctamente",
    "GarageCreate7": "Garaje actualizado correctamente",
    "TextUiCreateZone": "[MB1] + Punto   \n  [MB2] Eliminar ultimo punto   \n  [SCROLL] Altura  \n  [ENTER] Guardar Zona  \n  [BACKSPACE] Cerrar ",
    "TextUiCoords": "[E] +Coords  \n  [SCROLL] Direccion  \n  [BACKSPACE] Eliminar ultima coord  \n  [G] Nada/Player/Vehículo  \n  [ENTER] Guardar Coords",
    "private_addon": "",
    "private_addon_client": "",
    "toggle_blip_private": "Garajes Privados",
    "private_blip1": "Garajes privados marcados en el mapa",
    "private_blip2": "Garajes privados en el mapa desactivados",
    "private_exit": "Salir del garaje",
    "private_manage": "Gestionar",
    "private_manage1": "Dar acceso",
    "private_manage2": "Quitar acceso",
    "private_manage4": "Gestiona quién tiene acceso al garaje",
    "private_manage5": "Almacén",
    "private_manage6": "Seleccionar garaje",
    "private_manage7": "[E] Guardar Vehículo",
    "private_manage8": "Comprar | %s",
    "private_manage9": "### **Precio:** %s $  \n ### **Plazas de estacionamiento:** %s  \n  ![image](%s)",
    "private_manage10": "Método de pago",
    "private_manage11": "Seleccionar",
    "private_manage12": "Efectivo",
    "private_manage13": "Banco",
    "private_manage14": "Crear",
    "private_manage15": "%s - Plazas: %s",
    "private_manage16": "Puerta de entrada  \n  [E] Establecer coordenadas  \n  [SCROLL] Dirección",
    "private_manage17": "Depositar Vehículo  \n  [E] Establecer coordenadas  \n  [SCROLL] Dirección",
    "private_manage18": "Gestión de garajes privados",
    "private_manage19": "Crear nuevo garaje privado",
    "private_manage20": "Nombre",
    "private_manage21": "Precio",
    "private_manage22": "Interior",
    "private_manage23": "Precio: %s$ \n Dueño: %s \n (Haz clic para marcar en el radar)",
    "private_manage24": "A la venta: %s",
    "private_manage25": "Only the driver may be in the vehicle...",
    "private_addon_server": "",
    "private_manage_s1": "Garaje Privado",
    "private_manage_s2": "No puedes poseer más de %d garajes privados.",
    "private_manage_s3": "Enhorabuena, ahora eres el propietario de %s",
    "private_manage_s4": "No tienes suficiente dinero.",
    "private_manage_s5": "No se encontró ningún espacio disponible",
    "private_manage_s6": "No puedes guardar este vehículo aquí.",
    "private_manage_s7": "No tienes acceso para sacar este vehículo.",
    "private_manage_s8": "No tienes acceso a este garaje.",
    "private_manage_s9": "¡Este nombre ya existe!",
    "private_manage_s10": "Se creó correctamente el garaje con nombre [ %s ] con un precio de [ %s$ ], ID: %s",
    "private_manage_s11": "No Player ID",
    "private_manage_s12": "Te dieron permiso para entrar al garaje %s",
    "private_manage_s13": "Acceso retirado a %s",
    "private_manage_s14": "",
    "private_manage_s15": "",
    "private_ui1": "Espacios:",
    "private_ui2": "Comprar garaje",
    "private_ui3": "Propietario",
    "private_ui4": "Precio",
    "private_ui5": "Ubicación",
    "private_ui6": "Espacios",
    "private_ui7": "Espacios ocupados",
    "private_ui8": "Garaje",
    "private_ui9": "Acceso",
    "private_ui10": "Vehículos",
    "private_ui11": "Agregar acceso",
    "private_ui12": "Espacio",
    "private_ui13": "Nombre",
    "private_ui14": "Placa",
    "private_ui15": "Opciones",
    "private_ui16": "Acceso",
    "private_ui17": "Renombrar",
    "private_ui18": "Dar llave",
    "ui_name1": "Nombre",
    "ui_name2": "Renombrar vehículo",
    "ui_name3": "Cambiar"
};


const LangContext = createContext<Lang>(DevLang);

export const LangProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [lang, setLang] = useState<Lang>(DevLang);

    useNuiEvent<Lang>('mGarage:Lang', (data) => {
        setLang(data);
    });

    useEffect(() => {
        if (isEnvBrowser()) {
            setLang(DevLang);
        } else {
            fetchNui<Lang>('mGarage:Lang')
                .then(data => {
                    setLang(data);
                })
                .catch(error => {
                    console.error('Error fetching language data:', error);
                });
        }
    }, []);

    const value = useMemo(() => lang, [lang]);

    return (
        <LangContext.Provider value={value}>
            {children}
        </LangContext.Provider>
    );
};

export const useLang = () => {
    return useContext(LangContext);
};
