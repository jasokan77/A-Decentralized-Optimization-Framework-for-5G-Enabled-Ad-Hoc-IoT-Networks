function [decoded_signal, remaining_signal] = SIC_Decode(received_signal, power, original_signal, max_power)
    % Simulate SIC decoding process
    decoded_signal = 0;
    
    if power > 0.99 * max_power % Decoding is successful if power is high enough
        decoded_signal = original_signal;
        remaining_signal = received_signal - power * original_signal;
    else
        remaining_signal = received_signal;
    end
end