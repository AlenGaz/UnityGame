using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using Mirror;

[RequireComponent(typeof(TurnOffRemotePlayer))]
public class MovementEvents : NetworkBehaviour
{
    public UnityEvent m_OnMovementStartEvents;
    public UnityEvent m_OnMovementEndEvents;
    public Animator my_Animator;
    protected GridMovement _gridMovement;

    public GridObject _gridObject;
    public Vector2Int _gridPosition;
    public NetworkIdentity netIdentity;


    private void Awake()
    {
        _gridMovement = GetComponent<GridMovement>();
        _gridObject = GetComponent<GridObject>();
        netIdentity = GetComponent<NetworkIdentity>();
    }


    protected void OnEnable()
    {
        _gridMovement.OnMovementStart += OnMovementStart;
        _gridMovement.OnMovementEnd += OnMovementEnd;
    }

    protected void OnDisable()
    {
        _gridMovement.OnMovementStart -= OnMovementStart;
        _gridMovement.OnMovementEnd -= OnMovementEnd;
    }

    public void OnMovementStart(GridMovement gridMovement, GridTile startGridTile, GridTile endGridTile)
    {
        if (m_OnMovementStartEvents != null)
        {
            m_OnMovementStartEvents.Invoke();
            if (my_Animator == null)
            {
                my_Animator = gameObject.GetComponent<TurnOffRemotePlayer>().m_Animator;
            }
            my_Animator.SetBool("IsMoving", true);
        }
    }

    public void OnMovementEnd(GridMovement gridMovement, GridTile startGridTile, GridTile endGridTile)
    {
        if (m_OnMovementEndEvents != null)
            m_OnMovementEndEvents.Invoke();
        my_Animator.SetBool("IsMoving", false);
        _gridPosition = gameObject.GetComponent<GridObject>().m_GridPosition;
        CmdChangeGridPosition(_gridPosition, netIdentity.netId);
    }

    [Command (channel= 1, ignoreAuthority = true)] 
    private void CmdChangeGridPosition(Vector2Int gridPos, uint id)
    {
        //Debug.Log("CmdChangeGridPosition called.");
        gameObject.GetComponent<GridObject>().m_GridPosition = gridPos;
        gameObject.GetComponent<GridObject>().m_GridPosition = gridPos;
        //Debug.Log(gridPos);
        RpcUpdateGridPosition(gridPos, id);

    }

    [ClientRpc (channel = 1)]
    private void RpcUpdateGridPosition(Vector2Int gridPos, uint id)
    {
        //Debug.Log("RpcUpdateGridPosition called.");

        if (isLocalPlayer == true)
        { //Not correcting the local players position based on servers information
            return;
        }
        else
        {
            gameObject.GetComponent<GridObject>().m_GridPosition = gridPos;
        }

    }
}




