using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;


[RequireComponent(typeof(GridMovement))]
[RequireComponent(typeof(GridObject))]
public class KeyboardDrivenController :  MonoBehaviour{

    protected Vector2Int _currentInput = Vector2Int.zero;
    protected Vector2Int _queuedInput = Vector2Int.zero;
    [SerializeField]
    protected GridObject _gridObject;
    [SerializeField]
    protected GridMovement _gridMovement;

    /*---------------------------------------------------------*/
    //diagonal direction vectors
    Vector2 dirvectorQ = new Vector2(-1, 1);
    Vector2 dirvectorE = new Vector2(1, 1);
    Vector2 dirvectorZ = new Vector2(-1, -1);
    Vector2 dirvectorC = new Vector2(1, -1);
    //updown direction vectors 
    Vector2 dirvector4 = new Vector2Int(-1, 0); // left
    Vector2 dirvector8 = new Vector2Int(0, 1);  // top
    Vector2 dirvector6 = new Vector2Int(1, 0);  // right
    Vector2 dirvector2 = new Vector2Int(0, -1); // bottom

    public CharacterPathfinder characterPathfinder;


    [Header("Movement Settings")]
    public bool m_AnimateMovement = false;
    public bool m_RotateTowardsDirection = false;

    public int setNextPathPointIndex; //used to break mouse movement
    public float normalMoveSpeed;
    public float diagonalMoveSpeed;
    public float moveSpeed;


    [Header ("Input Settings")]
    public bool m_SwapAxis = false;
    public bool m_InvertXAxis = false;
    public bool m_InvertYAxis = false;

    // CHAT SETTINGS, need to drop the chat input field into this
    public GameObject inputFieldSlot;
    public InputField inputField;

    

    protected virtual void Reset() {
        Setup();
    }


    protected virtual void Setup() {
        _gridObject = GetComponent<GridObject>();
        _gridMovement = GetComponent<GridMovement>();
        
}

    protected virtual void OnEnable() {
        _gridMovement.OnMovementEnd += MovementEnded;
    }

    protected virtual void OnDisable() {
        _gridMovement.OnMovementEnd -= MovementEnded;
    }

    protected virtual void Update() {

            if (inputField.isFocused)
            {
                return;
            }
            _currentInput = GetKeyboardInput();
            ExecuteInput();
            
    }

    
    
    void Awake()
    {
       
         normalMoveSpeed = GetComponent<GridMovement>().MoveAnimDuration; // for resetting after changing movespeed
        diagonalMoveSpeed = GetComponent<GridMovement>().MoveAnimDuration * 1.51f; // for slowing down diagonal movement

        //GetComponent<GridMovement>().MoveAnimDuration = moveSpeed;
        //diagonalMoveSpeed = moveSpeed * 1.51f;
        //GetComponent<Cooldown>().DefaultDuration = moveSpeed * 0.97f;


        inputFieldSlot = GameObject.Find("Chat/InputField");
        inputField = inputFieldSlot.GetComponent<InputField>();


    }

    // Gets the current keyboard input
    public virtual Vector2Int GetKeyboardInput()
    {
        var invertX = m_InvertXAxis ? -1 : 1;
        var invertY = m_InvertYAxis ? -1 : 1;
        Vector2 input = m_SwapAxis ? new Vector2(Input.GetAxisRaw("Vertical") * invertX, Input.GetAxisRaw("Horizontal") * invertY) : new Vector2(Input.GetAxisRaw("Horizontal") * invertX, Input.GetAxisRaw("Vertical") * invertY);
        bool flag = Input.GetButton("Up") || Input.GetButton("Down") || Input.GetButton("Left") || Input.GetButton("Right");


        var direction = Vector2Int.zero;
        /*if (flag)
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = input.ToVector2Int();
        }*/

        direction = extendedKeyboardInput(direction);
        

        return direction;
    }

    private Vector2Int extendedKeyboardInput(Vector2Int direction)
    {

        if (Input.GetKeyDown(KeyCode.Return))
        {
            inputField.ActivateInputField();

        }

        if (Input.GetKey(KeyCode.DownArrow))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector2.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.LeftArrow))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector4.ToVector2Int();
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector6.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.UpArrow))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector8.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.S))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector2.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.A))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector4.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.W))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector8.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.D))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector6.ToVector2Int();
        }
            // DEFINED Q Z E C TO MOVE DIAGONALLY
            if (Input.GetKeyDown(KeyCode.Q) || Input.GetKeyDown(KeyCode.Keypad7))
        {
        
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1; //works to break mouse movement if a key is pressed to walk instead.
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorQ.ToVector2Int();
            

        }
        if (Input.GetKeyDown(KeyCode.E) || Input.GetKeyDown(KeyCode.Keypad9))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorE.ToVector2Int();
            

        }
        if (Input.GetKeyDown(KeyCode.Z) || Input.GetKeyDown(KeyCode.Keypad1))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorZ.ToVector2Int();

        }
        if (Input.GetKeyDown(KeyCode.C) || Input.GetKeyDown(KeyCode.Keypad3))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorC.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.Keypad2))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector2.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.Keypad4))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector4.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.Keypad8))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector8.ToVector2Int();
        }

        if (Input.GetKey(KeyCode.Keypad6))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = normalMoveSpeed;
            direction = dirvector6.ToVector2Int();
        }

        if (Input.GetKeyDown(KeyCode.Keypad1))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorZ.ToVector2Int();
        }

        if (Input.GetKeyDown(KeyCode.Keypad3))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorC.ToVector2Int();
        }

        if (Input.GetKeyDown(KeyCode.Keypad7))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorQ.ToVector2Int();
        }

        if (Input.GetKeyDown(KeyCode.Keypad9))
        {
            GetComponent<CharacterPathfinder>().m_NextPathpointIndex = -1;
            GetComponent<GridMovement>().MoveAnimDuration = diagonalMoveSpeed;
            direction = dirvectorE.ToVector2Int();
        }

        return direction;
    }



    protected virtual void ExecuteInput(Vector2Int? direction = null) {
        Vector2Int actionDirection;
            if (!direction.HasValue) {
                actionDirection = _currentInput;
            } else {
                actionDirection = direction.Value;
               
            }

            // If the direction is null/zero return
            if (actionDirection == Vector2Int.zero)
                return;

            // Try to move to the target position
            var targetPosition = _gridObject.m_GridPosition + actionDirection;
            
            GridObject targetOnGridTile = GridManager.Instance.GetGridObjectAtPosition(targetPosition);
            GridTile _targetGridtile = GridManager.Instance.GetGridTileAtPosition(targetPosition);

            ///////HANDLING DIRECTIONAL MOVEMENT BLOCKING ON GRIDTILES///////////////////////////////////////
            if (actionDirection == Vector2Int.up && _targetGridtile.blockingFromSouthToNorth)
            {
                return;
            }
            if (actionDirection == Vector2Int.down && _targetGridtile.blockingFromNorthToSouth)
            {
                return;
            }
            if (actionDirection == Vector2Int.left && _targetGridtile.blockingFromWestToEast)
            {
                return;
            }
            if (actionDirection == Vector2Int.right && _targetGridtile.blockingFromEastToWest)
            {
                return;
            }
        //////////////////////////////////////////////////////////////////////////////////////////////////




        if (targetOnGridTile != null)
        {
            if (targetOnGridTile.gameObject.CompareTag("Spell"))
            {
                Debug.Log("Detected Spell on tile");

                //_gridMovement.MoveTo(_targetGridtile, true, true);
                //_gridMovement.MoveTo(_targetGridtile, false, false);
            }
        }
            MovementResult movementResult = _gridMovement.TryMoveToNeighborInPosition(targetPosition, m_AnimateMovement, m_RotateTowardsDirection);
        
            // Queue the desired input if the movement is currently in cooldown
            if (movementResult == MovementResult.Cooldown) {
                _queuedInput = _currentInput;
                return;
            }

        if (targetOnGridTile != null)
        {
           
            if (targetOnGridTile.gameObject.CompareTag("Character") || targetOnGridTile.gameObject.CompareTag("Enemy"))
             {
                 Debug.Log("There's an object at TargetGridPosition");
                 return;
             }

           
        }


        // If movement was succesful or failed for some other reason we remove the current input
        _currentInput = Vector2Int.zero;
    }


    protected virtual void ExecuteQueuedInput() {
        // If there is not queued input direction
        if (_queuedInput == Vector2Int.zero) {
            return;
        }

        Vector2Int specificAction = _queuedInput;
        Clear_queuedInput();
        ExecuteInput(specificAction);
    }

    // Clear the queue
    protected virtual void Clear_queuedInput() {
        _queuedInput = Vector2Int.zero;
    }

    // Callback for the movement ended on GridMovement, used to execute queued input
    protected virtual void MovementEnded(GridMovement movement, GridTile fromGridPos, GridTile toGridPos) {
        ExecuteQueuedInput();
    }

    // This method will be used in future updates for mobile devices tapping implementation 
    protected virtual Vector2Int GetDefaultMoveDirection() {
        return Vector2Int.up;
    }
    
}
