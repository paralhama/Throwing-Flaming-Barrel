#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
    for(int i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamagePlayer);
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePlayer);
}

int LastPlayerToThrowObject[2049] = {-1, ...};

public Action OnTakeDamagePlayer(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    char entname[64], entname2[64], modelname[128];
    
    GetEntityClassname(attacker, entname, sizeof(entname));
    GetEntityClassname(inflictor, entname2, sizeof(entname2));
    
    if(strcmp(entname, "entityflame") == 0 && strcmp(entname2, "prop_physics_respawnable") == 0)
    {
        // Verifica o modelo do prop
        GetEntPropString(inflictor, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        
        // Verifica se é o barril explosivo
        if(StrContains(modelname, "barrel2_explosive", false) != -1 || StrContains(modelname, "barrel1_explosive", false) != -1)
        {
            if(LastPlayerToThrowObject[inflictor] != -1 && IsClientInGame(LastPlayerToThrowObject[inflictor]))
            {
                attacker = LastPlayerToThrowObject[inflictor];
                inflictor = LastPlayerToThrowObject[inflictor];
                return Plugin_Changed;
            }
        }
    }
    
    return Plugin_Continue;
}

int oldButtons[MAXPLAYERS+1] = {0, ...};

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (buttons & IN_SPEED && !(oldButtons[client] & IN_SPEED))
    {
        int item = GetEntPropEnt(client, Prop_Send, "m_hAttachedObject");    
        
        if(IsValidEntity(item))
        {
            char classname[64], modelname[128];
            GetEntityClassname(item, classname, sizeof(classname));
            
            // Verifica se é um prop_physics_respawnable
            if(strcmp(classname, "prop_physics_respawnable") == 0)
            {
                // Verifica o modelo
                GetEntPropString(item, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
                
                // Se for o barril explosivo
                if(StrContains(modelname, "barrel2_explosive", false) != -1 || StrContains(modelname, "barrel1_explosive", false) != -1)
                {
                    LastPlayerToThrowObject[item] = client;
                    AcceptEntityInput(item, "Ignite", client, client);
                }
            }
        }
    }
    
    oldButtons[client] = buttons;
    return Plugin_Continue;
}