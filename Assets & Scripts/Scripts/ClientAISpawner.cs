using UnityEngine;
using Mirror;
using System.Collections.Generic;

public class ClientAISpawner : MonoBehaviour
{
    public static ClientAISpawner getInstance;
    void Awake() { getInstance = this; }

    [SerializeField] AIData[] ais;

    List<AI> spawnedAIs = new List<AI>();

    void Start()
    {
        if (!NetworkServer.active)
            Destroy(this);
    } 

    public void Spawn(int id, int aiId, Vector3 pos, Quaternion rot)
    {
        AIData data = getAIData(aiId);
        if (data == null)
            return;
        Debug.Log("Spawning ai ON client ai SPAWNER: " + (aiId != null));
        GridTile tile = GridManager.Instance.GetGridTileAtPosition(Vector2Int.CeilToInt(new Vector2(pos.x, pos.z)));
        GridObject go = GridManager.Instance.InstantiateGridObject(data.prefab.GetComponent<GridObject>(), (Vector2Int.CeilToInt(new Vector2(pos.x, pos.z))));

        // GameObject go = Instantiate(data.prefab, pos, rot);
        AI ai = go.GetComponent<AI>();
        ai.Init(id, data, null);
        spawnedAIs.Add(ai);
        //if this doesnt sync, then use network spawn and then when spawned add them in list and then check with netid
    }
    public void Despawn(int id)
    {
        for (int i = 0; i < spawnedAIs.Count; i++)
        {
            if (spawnedAIs[i].id == id)
            {
                Destroy(spawnedAIs[i]);
                spawnedAIs.RemoveAt(i);
                return;
            }
        }
    }

    AIData getAIData(int id)
    {
        for (int i = 0; i < ais.Length; i++)
        {
            if (ais[i].aiID == id)
                return ais[i];
        }

        return null;
    }
}