classdef motor < handle
    
    properties(SetAccess=private,SetObservable,AbortSet)
        % Default here will only matter if motors aren't set
        Homed = false;
        Moving = false;              % Track this to update position
    end
    
    properties(SetAccess=private)
        position = [1 1 1];   % Position [x, y, z]
        motors = cell(1,3); % A cell array for the 3 motors {X,Y,Z} (list would require having "null" objects)
        calibration = [2 2 2]; % ratio between position read by .Net and actual position.
    end
    
    properties(Constant)
        Travel = [0 8];
    end
    
    properties (Constant, Hidden)
        MOTORPATHDEFAULT='C:\Program Files\Thorlabs\Kinesis\';
        % DLL files to be loaded
        DEVICEMANAGERDLL='Thorlabs.MotionControl.DeviceManagerCLI.dll';
        DEVICEMANAGERCLASSNAME='Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI';
        GENERICMOTORDLL='Thorlabs.MotionControl.GenericMotorCLI.dll';
        GENERICMOTORCLASSNAME='Thorlabs.MotionControl.GenericMotorCLI.GenericMotorCLI';
        STEPPERMOTORDLL='Thorlabs.MotionControl.Benchtop.StepperMotorCLI.dll';
        STEPPERMOTORCLASSNAME='Thorlabs.MotionControl.Benchtop.StepperMotorCLI.BenchtopStepperMotor';
        
        % Default intitial parameters 
%         DEFAULTVEL=10;           % Default velocity
%         DEFAULTACC=10;           % Default acceleration
        TPOLLING=250;            % Default polling time
        TIMEOUTSETTINGS=7000;    % Default timeout time for settings change
        TIMEOUTMOVE=100000;      % Default time out time for motor move
    end
    
    properties 
       % These properties are within Matlab wrapper 
       isconnected=false;           % Flag set if device connected
       serialnumbers;                % Device serial number
       controllername;              % Controller Name
       controllerdescription        % Controller Description
       stagename;                   % Stage Name
       acceleration;                % Acceleration
       maxvelocity;                 % Maximum velocity limit
       minvelocity;                 % Minimum velocity limit
    end
    properties (Hidden)
       % These are properties within the .NET environment. 
       deviceNET;                   % Device object within .NET
       channelsNET;                    % Channel object within .NET (3 *1 cell)
       motorSettingsNET;            % motorSettings within .NET
       currentDeviceSettingsNET;    % currentDeviceSetings within .NET
       deviceInfoNET;               % deviceInfo within .NET
    end
    
    methods
        function h = motor()  % Instantiate motor object
            motor.loaddlls; % Load DLLs (if not already loaded)
        end
        function connect(h, serialNo)
            h.listdevices();
            h.deviceNET = Thorlabs.MotionControl.Benchtop.StepperMotorCLI.BenchtopStepperMotor.CreateBenchtopStepperMotor(serialNo);
            h.isconnected = h.deviceNET.IsConnected(); 
            disp('device connection status at point 1 is')
            disp(h.isconnected)
            if ~h.isconnected
                if str2double(serialNo(1:2)) == double(Thorlabs.MotionControl.Benchtop.StepperMotorCLI.BenchtopStepperMotor.DevicePrefix70)
                    h.deviceNET = Thorlabs.MotionControl.Benchtop.StepperMotorCLI.BenchtopStepperMotor.CreateBenchtopStepperMotor(serialNo);

                else
                    error('Device not recoginised')
                end  
                
                for i = 1:3
                    h.channelsNET{i} = h.deviceNET.GetChannel(i);
                    h.channelsNET{i}.ClearDeviceExceptions();
                end
                
                % Connect to device via .NET interface
                h.deviceNET.Connect(serialNo);
                h.isconnected = h.deviceNET.IsConnected(); 
                disp('device connection status at point 2 is')
                disp(h.isconnected)
                
                h.initialize(serialNo)
                
            else
                error('device is already connected')
            end
           updatestatus(h)
        end
        
        
        function initialize(h, serialNo) % Initialize the channels separately
            for i = 1:3
                try
                    if ~h.channelsNET{i}.IsSettingsInitialized() % Initialize x channel
                        h.channelsNET{i}.WaitForSettingsInitialized(h.TIMEOUTSETTINGS);
                    else
                        disp('Device Already Initialized.')
                    end
                    if ~h.channelsNET{i}.IsSettingsInitialized() % Initialize x channel
                        error('Unable to initialize device')
                    end
                    h.channelsNET{i}.StartPolling(h.TPOLLING);
                    h.channelsNET{i}.EnableDevice();

                    % Initializing motor configuration
                    deviceConfigMag = Thorlabs.MotionControl.DeviceManagerCLI.DeviceConfigurationManager;
                    deviceConfigMagInstance = deviceConfigMag.Instance();
                    deviceConfigMagInstance.CreateDeviceConfiguration(serialNo, uint32(70), true);
                    deviceID = h.channelsNET{i}.DeviceID;
                    deviceConfig = deviceConfigMag.Instance().GetDeviceConfiguration(deviceID);
                    setting = deviceConfig.ApplicationSettingsLoadOption;
                    h.motorSettingsNET{i} = h.channelsNET{i}.GetMotorConfiguration(serialNo, setting);

                    % Initialize current motor settings
                    h.currentDeviceSettingsNET{i}=h.channelsNET{i}.MotorDeviceSettings;
                    h.deviceInfoNET{i} = h.channelsNET{i}.GetDeviceInfo();
                catch
                    error(['Unable to initialize channel ', num2str(i)]);
                end
            end
            
        end
        
        function disconnect(h)
            h.isconnected=h.deviceNET.IsConnected();
            if h.isconnected
                try
                    for i = 1:3
                        h.channelsNET{i}.StopPolling()
                    end
                    h.deviceNET.Disconnect(true)
                catch
                    error(['Unable to disconnect device',h.serialnumbers{i}]);
                end
                h.isconnected = h.deviceNET.IsConnected();
            else % Cannot disconnect because device not connected
                error('Device not connected.')
            end
        end
        
        function updatestatus(h)
            h.isconnected = h.deviceNET.IsConnected(); % connection status            
            for i = 1:3
                h.serialnumbers{i}=char(h.channelsNET{i}.DeviceID);          % update serial number
                h.controllername{i}=char(h.deviceInfoNET{i}.Name);        % update controleller name
                h.controllerdescription{i}=char(h.deviceInfoNET{i}.Description);  % update controller description
                h.stagename{i}=char(h.motorSettingsNET{i}.DeviceSettingsName);    % update stagename                
                velocityparams{i}=h.channelsNET{i}.GetVelocityParams();             % update velocity parameter
                h.acceleration{i}=System.Decimal.ToDouble(velocityparams{i}.Acceleration); % update acceleration parameter
                h.maxvelocity{i}=System.Decimal.ToDouble(velocityparams{i}.MaxVelocity);   % update max velocit parameter
                h.minvelocity{i}=System.Decimal.ToDouble(velocityparams{i}.MinVelocity);   % update Min velocity parameter
                h.position(i) = System.Decimal.ToDouble(h.channelsNET{i}.Position); % x position
            end
            h.position = h.position ./ h.calibration;
        end
        
        function home(h)
            for i = 1:3
                workDone=h.channelsNET{i}.InitializeWaitHandler();     % Initialise Waithandler for timeout
                h.channelsNET{i}.Home(workDone);                       % Home device via .NET interface
                h.channelsNET{i}.Wait(h.TIMEOUTMOVE);                  % Wait for move to finish
                            
            end
            updatestatus(h); % Update status variables from device
        end
        
        function moveto(h, target_pos)
            target_pos = target_pos .* h.calibration;
            for i = 1:3
                try
                    workDone=h.channelsNET{i}.InitializeWaitHandler(); % Initialise Waithandler for timeout
                    h.channelsNET{i}.MoveTo(target_pos(i), workDone);       % Move device to position via .NET interface
                    h.channelsNET{i}.Wait(h.TIMEOUTMOVE);              % Wait for move to finish
                
                catch
                    error(['Unable to Move channel ',h.serialnumber{i},' to ',num2str(target_pos(i))]);
                end
            end
            updatestatus(h)
        end
    end
    
    methods (Static)
        function serialNumbers=listdevices()  % Read a list of serial number of connected devices
            motor.loaddlls; % Load DLLs.
            Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.BuildDeviceList();  % Build device list
            serialNumbersNet = Thorlabs.MotionControl.DeviceManagerCLI.DeviceManagerCLI.GetDeviceList(); % Get device list
            serialNumbers=cell(ToArray(serialNumbersNet)); % Convert serial numbers to cell array
        end
        function loaddlls()
            if ~exist(motor.DEVICEMANAGERCLASSNAME,'class')
                try
                    NET.addAssembly([motor.MOTORPATHDEFAULT,motor.DEVICEMANAGERDLL]);
                    NET.addAssembly([motor.MOTORPATHDEFAULT,motor.GENERICMOTORDLL]);
                    NET.addAssembly([motor.MOTORPATHDEFAULT,motor.STEPPERMOTORDLL]);
                catch
                    error('Unable to load .NET assemblies')
                end
            end
        end
    end
end