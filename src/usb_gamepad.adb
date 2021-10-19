with HAL; use HAL;
with HAL.GPIO; use HAL.GPIO;
with USB.Device;
with USB.Device.MIDI;
with USB.Device.Serial;
with USB.Device.HID.Gamepad;

with SAM.Device; use SAM.Device;
with SAM.USB;
with SAM_SVD.USB;
with SAM.Main_Clock;
with SAM.Clock_Generator;
with SAM.Clock_Generator.IDs;
with SAM.Clock_Setup_120Mhz;
with SAM.Port;
with SAM.Functions;

with Interfaces; use Interfaces;

with PyGamer; --  Elaborate PyGamer
pragma Unreferenced (PyGamer);

with PyGamer.Controls;
with pygamer_usb_gamepad_Config;

package body USB_Gamepad is

   Stack : USB.Device.USB_Device_Stack (Max_Classes => 3);
   Pad   : aliased USB.Device.HID.Gamepad.Instance;

   UDC : aliased SAM.USB.UDC
     (Periph          => SAM_SVD.USB.USB_Periph'Access,
      EP_Buffers_Size => 512,
      Max_Packet_Size => 64);

   USB_DP  : SAM.Port.GPIO_Point renames PA25;
   USB_DM  : SAM.Port.GPIO_Point renames PA24;
   USB_ID  : SAM.Port.GPIO_Point renames PA23;

   procedure Run is
      use type USB.Device.Init_Result;
   begin
      SAM.Clock_Generator.Configure_Periph_Channel
        (SAM.Clock_Generator.IDs.USB, SAM.Clock_Setup_120Mhz.Clk_48Mhz);

      SAM.Main_Clock.USB_On;

      USB_DP.Clear;
      USB_DP.Set_Mode (HAL.GPIO.Output);
      USB_DP.Set_Pull_Resistor (HAL.GPIO.Floating);
      USB_DP.Set_Function (SAM.Functions.PA25_USB_DP);

      USB_DM.Clear;
      USB_DM.Set_Mode (HAL.GPIO.Output);
      USB_DM.Set_Pull_Resistor (HAL.GPIO.Floating);
      USB_DM.Set_Function (SAM.Functions.PA25_USB_DP);

      USB_ID.Clear;
      USB_ID.Set_Mode (HAL.GPIO.Output);
      USB_ID.Set_Pull_Resistor (HAL.GPIO.Floating);
      USB_ID.Set_Function (SAM.Functions.PA23_USB_SOF_1KHZ);

      if not Stack.Register_Class (Pad'Access) then
         raise Program_Error;
      end if;

      if Stack.Initialize
        (UDC'Access,
         USB.To_USB_String ("Fabien"),
         USB.To_USB_String ("PyGamer Gamepad"),
         USB.To_USB_String (pygamer_usb_gamepad_Config.Crate_Version),
         UDC.Max_Packet_Size) /= USB.Device.Ok
      then
         raise Program_Error;
      end if;

      Stack.Start;

      declare
         S : Natural := 1;
      begin
         loop
            Stack.Poll;

            if Pad.Ready then
               PyGamer.Controls.Scan;
               declare
                  use USB.Device.HID.Gamepad;

                  X_Val : constant Integer_8 :=
                    Integer_8 (PyGamer.Controls.Joystick_X);

                  Y_Val : constant Integer_8 :=
                    Integer_8 (PyGamer.Controls.Joystick_Y);

                  Buttons : UInt8 := 0;
               begin
                  Pad.Set_Axis (X, X_Val);
                  Pad.Set_Axis (Y, Y_Val);

                  if PyGamer.Controls.Pressed (PyGamer.Controls.A) then
                     Buttons := Buttons or 2#0000_0001#;
                  end if;

                  if PyGamer.Controls.Pressed (PyGamer.Controls.B) then
                     Buttons := Buttons or 2#0000_0010#;
                  end if;

                  if PyGamer.Controls.Pressed (PyGamer.Controls.Sel) then
                     Buttons := Buttons or 2#0000_0100#;
                  end if;

                  if PyGamer.Controls.Pressed (PyGamer.Controls.Start) then
                     Buttons := Buttons or 2#0000_1000#;
                  end if;

                  Pad.Set_Buttons (Buttons);

                  Pad.Send_Report (UDC);
               end;
            end if;
         end loop;
      end;
   end Run;

end USB_Gamepad;
